import '../application/due_reminder_planner.dart';

/// Thin seam over the platform notification plugin so the scheduler (and its
/// tests) never touch `flutter_local_notifications` directly. The production
/// implementation is `LocalDeviceNotifications`; tests supply a fake.
///
/// Every method is best-effort: implementations must swallow platform errors
/// quietly (missing plugin on the test host, unsupported OS, revoked
/// permission) — device reminders are a convenience layer, never a crash
/// source.
abstract interface class DeviceNotifications {
  /// Whether this platform can arm scheduled device notifications at all.
  /// Android-only for now (the app ships as a sideloaded Android APK); false
  /// on the macOS test host, which keeps widget tests hermetic.
  bool get isSupported;

  /// Asks the OS for notification permission (Android 13+ POST_NOTIFICATIONS
  /// runtime prompt). Returns true when granted. A no-op returning false on
  /// unsupported platforms.
  Future<bool> requestPermission();

  /// Whether notifications are currently allowed for the app. Null when the
  /// platform cannot answer (e.g. unsupported platform).
  Future<bool?> areEnabled();

  /// Cancels every pending scheduled notification owned by the app.
  Future<void> cancelAll();

  /// Arms one scheduled notification at [reminder.when] (local wall clock).
  Future<void> schedule(PlannedReminder reminder);
}
