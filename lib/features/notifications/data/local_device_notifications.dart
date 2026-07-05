import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../application/device_notifications.dart';
import '../application/due_reminder_planner.dart';

/// `flutter_local_notifications`-backed [DeviceNotifications] — Android only.
///
/// Scheduling uses **inexact** alarms (`AndroidScheduleMode.inexactAllowWhileIdle`)
/// so no SCHEDULE_EXACT_ALARM permission is needed: a due reminder firing a few
/// minutes off 09:00 is fine. All notifications land on one channel,
/// "Pengingat jatuh tempo". Every call is wrapped so a platform failure
/// degrades to a silent no-op rather than an error surface.
class LocalDeviceNotifications implements DeviceNotifications {
  LocalDeviceNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationDetails(
    'due_reminders',
    'Pengingat jatuh tempo',
    channelDescription:
        'Pengingat H-3 dan H-1 untuk cicilan, langganan, dan utang.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  bool get isSupported => Platform.isAndroid;

  /// Lazily initializes the plugin + timezone database once. Returns false
  /// (and stays quiet) when the platform side is unavailable.
  Future<bool> _ensureReady() async {
    if (!isSupported) return false;
    if (_ready) return true;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        // Keep the default location; TZDateTime.from preserves the absolute
        // instant regardless, so reminders still fire at the right moment.
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> requestPermission() async {
    if (!await _ensureReady()) return false;
    try {
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool?> areEnabled() async {
    if (!await _ensureReady()) return null;
    try {
      return await _android?.areNotificationsEnabled();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!await _ensureReady()) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Best-effort.
    }
  }

  @override
  Future<List<int>> listPendingIds() async {
    if (!await _ensureReady()) return const [];
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return [for (final request in pending) request.id];
    } catch (_) {
      // Best-effort: an empty answer makes the scheduler skip pruning, which
      // only leaves stale reminders for the next resync to clean up.
      return const [];
    }
  }

  @override
  Future<void> cancelIds(List<int> ids) async {
    if (!await _ensureReady()) return;
    for (final id in ids) {
      try {
        await _plugin.cancel(id: id);
      } catch (_) {
        // Best-effort.
      }
    }
  }

  @override
  Future<void> schedule(PlannedReminder reminder) async {
    if (!await _ensureReady()) return;
    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
        notificationDetails: const NotificationDetails(android: _channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Best-effort: a reminder that fails to arm must never break the app.
    }
  }
}
