import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/data/dashboard_models.dart';
import '../../insights/data/insight_models.dart';
import '../../insights/data/insights_repository.dart';
import '../data/local_device_notifications.dart';
import 'device_notifications.dart';
import 'due_reminder_planner.dart';

/// The platform seam. Overridable in tests with a fake.
final deviceNotificationsProvider = Provider<DeviceNotifications>((ref) {
  return LocalDeviceNotifications();
});

/// App-lifetime scheduler for the local due reminders. Wired so that
/// [dashboardSummaryProvider]'s success path is the only summary-driven call
/// site (see [NotificationScheduler.requestResync]); rule toggles reach it via
/// [NotificationScheduler.resyncLatest] and logout via
/// [NotificationScheduler.clear].
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final scheduler = NotificationScheduler(
    device: ref.watch(deviceNotificationsProvider),
    loadRules: () =>
        ref.read(insightsRepositoryProvider).listNotificationRules(),
  );
  ref.onDispose(scheduler.dispose);
  return scheduler;
});

/// Keeps the device's scheduled notifications mirroring the freshest upcoming
/// dues:
///
/// - `requestResync(summary)` is called every time the dashboard summary
///   (re)loads — app start/login and every `invalidateBalances`-driven refresh.
///   Calls are **debounced/coalesced** (a burst of invalidations produces one
///   resync with the latest summary), so hooking the summary provider cannot
///   spam the notification manager. Runs are **serialized**: a new resync
///   never starts until the previous one finished, and it re-reads the latest
///   summary when it actually runs, so overlapping resyncs can't interleave.
/// - A resync fetches the user's server-side notification rules first. A
///   disabled/missing `due-reminder` rule ⇒ the plan is empty, so the resync
///   just clears pending reminders. If the rules endpoint **fails**, the
///   resync aborts quietly WITHOUT cancelling what's already armed
///   (fail-safe: never lose reminders over a flaky request).
/// - The plan itself is pure ([planDueReminders]): H-3/H-1 at 09:00 local,
///   past instants skipped, capped at [kMaxPlannedReminders]. The swap is
///   **arm-first, prune-after**: planned reminders are (re)scheduled in place
///   (deterministic ids overwrite), THEN ids no longer planned are cancelled —
///   a crash mid-resync leaves the old set or a superset armed, never nothing.
/// - `resyncLatest()` re-runs the resync from the last summary seen — the hook
///   for RULE toggles (Pengaturan → Aturan notifikasi), which change what
///   should be armed without any money mutation.
/// - `clear()` wipes everything (pending debounce, cached summary, armed
///   notifications) on logout / discarded session, so reminders carrying the
///   old account's amounts can't keep firing.
/// - Android 13+ permission: requested **once ever** automatically (on the
///   first resync that finds an enabled rule; remembered via
///   SharedPreferences), never nagging again — afterwards the explicit row on
///   Pengaturan → Aturan notifikasi is the only prompt trigger.
class NotificationScheduler {
  NotificationScheduler({
    required this.device,
    required this._loadRules,
    this.debounce = const Duration(seconds: 3),
  });

  static const _promptedPrefsKey = 'affluena.device_notif_prompted';

  final DeviceNotifications device;
  final Future<NotificationRulesResponse> Function() _loadRules;

  /// How long to coalesce back-to-back resync requests.
  final Duration debounce;

  Timer? _pending;
  DashboardSummary? _latestSummary;
  Future<void>? _inFlight;

  /// Bumped whenever a newer resync (or a [clear]) supersedes the current one;
  /// [resyncNow] re-checks it after every await so a stale run can never
  /// cancel or arm behind a fresher plan.
  int _generation = 0;

  /// Ask for a resync against [summary]'s dues. Cheap to call repeatedly:
  /// requests are coalesced and only the latest summary wins.
  void requestResync(DashboardSummary summary) {
    if (!device.isSupported) return;
    _latestSummary = summary;
    _pending?.cancel();
    _pending = Timer(debounce, _chainResync);
  }

  /// Re-runs the resync from the last summary this scheduler has seen — the
  /// hook for RULE changes (Pengaturan → Aturan notifikasi), which alter what
  /// should be armed without touching the money data. Returns false when no
  /// summary was ever seen; the caller should then refresh the dashboard
  /// summary instead, whose success path lands back here via [requestResync].
  bool resyncLatest() {
    // Nothing can be armed on an unsupported platform — report handled so the
    // caller doesn't refetch the summary for nothing.
    if (!device.isSupported) return true;
    if (_latestSummary == null) return false;
    _pending?.cancel();
    _pending = null;
    _chainResync();
    return true;
  }

  /// Serializes runs: the next resync is chained onto whatever is in flight
  /// and re-reads [_latestSummary] when it actually starts, so overlapping
  /// requests become ordered runs against the freshest summary instead of
  /// interleaving.
  void _chainResync() {
    final prev = _inFlight ?? Future<void>.value();
    _inFlight = prev.catchError((_) {}).then((_) {
      final latest = _latestSummary;
      if (latest == null) return Future<void>.value();
      return resyncNow(latest);
    });
  }

  /// Immediate resync (the debounced path lands here). Public for tests.
  Future<void> resyncNow(DashboardSummary summary) async {
    if (!device.isSupported) return;
    _latestSummary = summary;
    final gen = ++_generation;

    final NotificationRulesResponse rules;
    try {
      rules = await _loadRules();
    } catch (_) {
      // Fail-safe: no rules — schedule nothing new, keep what's armed, stay quiet.
      return;
    }
    if (gen != _generation) return; // Superseded while fetching rules.
    final enabledKeys = <String>{
      for (final rule in rules.rules)
        if (rule.enabled) rule.ruleKey,
    };

    await _maybeRequestPermissionOnce(enabledKeys);
    if (gen != _generation) return;

    final planned = planDueReminders(
      summary: summary,
      enabledRuleKeys: enabledKeys,
      now: clock.now(),
    );

    if (planned.isEmpty) {
      // Disabled rule / no dues: with nothing to arm, a plain cancel-all is
      // already crash-safe.
      await device.cancelAll();
      return;
    }

    // Arm-first: the planner's ids are deterministic, so re-scheduling an
    // already-armed id overwrites it in place. Only THEN prune ids that fell
    // out of the plan — a crash mid-resync leaves the old set or a superset
    // armed, never an empty pane (the next resync prunes leftovers).
    final plannedIds = <int>{for (final reminder in planned) reminder.id};
    for (final reminder in planned) {
      if (gen != _generation) return;
      await device.schedule(reminder);
    }
    if (gen != _generation) return;
    final pendingIds = await device.listPendingIds();
    if (gen != _generation) return;
    final stale = [
      for (final id in pendingIds)
        if (!plannedIds.contains(id)) id,
    ];
    if (stale.isNotEmpty) {
      await device.cancelIds(stale);
    }
  }

  /// Forgets everything and cancels every armed device notification — called
  /// (fire-and-forget) on logout and when a stored session is discarded, so
  /// due reminders carrying the old account's amounts/counterparties can't
  /// keep firing. Fail-quiet; safe on unsupported platforms.
  Future<void> clear() {
    _generation++; // Any in-flight resync aborts at its next checkpoint.
    _pending?.cancel();
    _pending = null;
    _latestSummary = null;
    final prev = _inFlight ?? Future<void>.value();
    return _inFlight = prev.catchError((_) {}).then((_) async {
      try {
        await device.cancelAll();
      } catch (_) {
        // Best-effort: the adapter is already fail-quiet; a logout must never
        // surface a notification error.
      }
    });
  }

  /// One-time automatic permission ask: only when a rule is enabled, and only
  /// if we have never auto-prompted before (per-device flag). The Pengaturan
  /// row remains the explicit re-trigger.
  Future<void> _maybeRequestPermissionOnce(Set<String> enabledKeys) async {
    if (enabledKeys.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_promptedPrefsKey) ?? false) return;
      await prefs.setBool(_promptedPrefsKey, true);
      await device.requestPermission();
    } catch (_) {
      // Quiet: permission can always be granted later from Pengaturan.
    }
  }

  /// Await any in-flight resync (test hook).
  Future<void> idle() async => await _inFlight;

  void dispose() {
    _pending?.cancel();
    _pending = null;
  }
}
