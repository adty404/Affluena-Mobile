import 'package:intl/intl.dart';

abstract final class AffluenaDateFormatter {
  // Text-bearing formats use the 'id_ID' locale so month/weekday names render
  // in Bahasa Indonesia (e.g. "Jun" -> "Jun"/"Mei", "Mon" -> "Sen"). The locale
  // data is loaded at startup via initializeDateFormatting('id_ID'). _monthKey
  // (an API key) and _time stay locale-neutral.
  static final DateFormat _shortDate = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy · HH:mm', 'id_ID');
  static final DateFormat _monthKey = DateFormat('yyyy-MM');
  static final DateFormat _monthLabel = DateFormat('MMM yyyy', 'id_ID');
  static final DateFormat _monthLabelFull = DateFormat('MMMM yyyy', 'id_ID');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _dayHeader = DateFormat('EEE, d MMM yyyy', 'id_ID');

  static String shortDate(String isoString) {
    return _shortDate.format(DateTime.parse(isoString).toLocal());
  }

  /// Local date and time-of-day, e.g. "20 Jun 2026 · 14:05".
  static String dateTime(String isoString) {
    return _dateTime.format(DateTime.parse(isoString).toLocal());
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

  /// A day-group heading: "Hari ini", "Kemarin", or "EEE, d MMM yyyy".
  static String dayHeader(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today
        .difference(DateTime(day.year, day.month, day.day))
        .inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return _dayHeader.format(day);
  }

  static String monthKey(DateTime date) {
    return _monthKey.format(date);
  }

  /// Normalizes a stored API date string to the `YYYY-MM-DD` wire format that
  /// the API's **date-only** fields require (e.g. a subscription's
  /// `next_due_date`, an installment's `start_date`).
  ///
  /// The API serializes DATE columns as full RFC3339 UTC-midnight timestamps
  /// (`"2026-07-19T00:00:00Z"`); re-sending that value verbatim into a strict
  /// date-only field is rejected with a 400. This takes the calendar-date
  /// prefix of the string WITHOUT any timezone conversion (the prefix *is* the
  /// stored calendar date — converting to local time could shift the day).
  /// Already-short (`"2026-07-19"`) values pass through unchanged, and
  /// anything that doesn't parse as a date is returned as-is so the API stays
  /// the validator of last resort.
  static String apiDate(String value) {
    final trimmed = value.trim();
    if (DateTime.tryParse(trimmed) == null) return trimmed;
    return _dateOnlyPrefix.firstMatch(trimmed)?.group(0) ?? trimmed;
  }

  static final RegExp _dateOnlyPrefix = RegExp(r'^\d{4}-\d{2}-\d{2}');

  /// Human-readable month, e.g. "Jun 2026".
  static String monthLabel(DateTime date) {
    return _monthLabel.format(date);
  }

  /// Full human-readable month, e.g. "Juni 2026".
  static String monthLabelFull(DateTime date) {
    return _monthLabelFull.format(date);
  }
}
