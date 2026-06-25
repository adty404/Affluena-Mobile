import 'package:intl/intl.dart';

abstract final class AffluenaDateFormatter {
  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _monthKey = DateFormat('yyyy-MM');
  static final DateFormat _monthLabel = DateFormat('MMM yyyy');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dayHeader = DateFormat('EEE, d MMM yyyy');

  static String shortDate(String isoString) {
    return _shortDate.format(DateTime.parse(isoString).toLocal());
  }

  /// Local time-of-day, e.g. "14:05".
  static String time(String isoString) {
    return _time.format(DateTime.parse(isoString).toLocal());
  }

  /// The local calendar day (midnight) for grouping transactions by day.
  static DateTime localDay(String isoString) {
    final dt = DateTime.parse(isoString).toLocal();
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// A day-group heading: "Today", "Yesterday", or "EEE, d MMM yyyy".
  static String dayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today
        .difference(DateTime(day.year, day.month, day.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return _dayHeader.format(day);
  }

  static String monthKey(DateTime date) {
    return _monthKey.format(date);
  }

  /// Human-readable month, e.g. "Jun 2026".
  static String monthLabel(DateTime date) {
    return _monthLabel.format(date);
  }
}
