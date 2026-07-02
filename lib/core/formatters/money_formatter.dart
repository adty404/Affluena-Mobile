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

  /// Ultra-compact rupiah for dense surfaces (calendar day cells):
  /// 950 → `950`, 25000 → `25rb`, 1200000 → `1,2jt`, 2500000000 → `2,5M`.
  /// No `Rp` prefix — callers add their own sign/colour.
  static String compactIdr(int amountMinor) {
    final n = amountMinor.abs();
    if (n >= 1000000000) return '${_compactValue(n / 1000000000)}M';
    if (n >= 1000000) return '${_compactValue(n / 1000000)}jt';
    if (n >= 1000) return '${_compactValue(n / 1000)}rb';
    return n.toString();
  }

  static String _compactValue(double value) {
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) return rounded.round().toString();
    return rounded.toStringAsFixed(1).replaceAll('.', ',');
  }
}
