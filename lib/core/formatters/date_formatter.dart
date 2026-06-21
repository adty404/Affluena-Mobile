import 'package:intl/intl.dart';

abstract final class AffluenaDateFormatter {
  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _monthKey = DateFormat('yyyy-MM');

  static String shortDate(String isoString) {
    return _shortDate.format(DateTime.parse(isoString).toLocal());
  }

  static String monthKey(DateTime date) {
    return _monthKey.format(date);
  }
}
