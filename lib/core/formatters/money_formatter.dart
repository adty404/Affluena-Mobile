import 'package:intl/intl.dart';

abstract final class MoneyFormatter {
  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String idr(int amountMinor) {
    return _idr.format(amountMinor);
  }

  static String signedIdr(int amountMinor) {
    if (amountMinor == 0) return idr(0);
    final sign = amountMinor > 0 ? '+' : '-';
    return '$sign${idr(amountMinor.abs())}';
  }
}
