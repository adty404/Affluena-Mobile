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
/// [dashboardSummaryProvider]'s success path is the only call site — see
/// [NotificationScheduler.requestResync].
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final scheduler = NotificationScheduler(
    device: ref.watch(deviceNotificationsProvider),
    loadRules: () => ref.read(insightsRepositoryProvider).listNotificationRules(),
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
///   spam the notification manager.
/// - A resync fetches the user's server-side notification rules first. A
///   disabled/missing `due-reminder` rule ⇒ the plan is empty, so the resync
///   just clears pending reminders. If the rules endpoint **fails**, the
///   resync aborts quietly WITHOUT cancelling what's already armed
///   (fail-safe: never lose reminders over a flaky request).
/// - The plan itself is pure ([planDueReminders]): H-3/H-1 at 09:00 local,
///   past instants skipped, capped at [kMaxPlannedReminders]. The scheduler
///   then does cancel-all + arm-batch, so stale reminders never linger.
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

  /// Ask for a resync against [summary]'s dues. Cheap to call repeatedly:
  /// requests are coalesced and only the latest summary wins.
  void requestResync(DashboardSummary summary) {
    if (!device.isSupported) return;
    _latestSummary = summary;
    _pending?.cancel();
    _pending = Timer(debounce, () {
      final latest = _latestSummary;
      if (latest != null) {
        _inFlight = resyncNow(latest);
      }
    });
  }

  /// Immediate resync (the debounced path lands here). Public for tests.
  Future<void> resyncNow(DashboardSummary summary) async {
    if (!device.isSupported) return;

    final NotificationRulesResponse rules;
    try {
      rules = await _loadRules();
    } catch (_) {
      // Fail-safe: no rules — schedule nothing new, keep what's armed, stay quiet.
      return;
    }
    final enabledKeys = <String>{
      for (final rule in rules.rules)
        if (rule.enabled) rule.ruleKey,
    };

    await _maybeRequestPermissionOnce(enabledKeys);

    final planned = planDueReminders(
      summary: summary,
      enabledRuleKeys: enabledKeys,
      now: clock.now(),
    );

    await device.cancelAll();
    for (final reminder in planned) {
      await device.schedule(reminder);
    }
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
