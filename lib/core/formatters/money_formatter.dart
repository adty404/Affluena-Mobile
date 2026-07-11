import 'package:intl/intl.dart';

abstract final class MoneyFormatter {
  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// The masked-balance placeholder shown when amounts are hidden (the
  /// Beranda eye toggle — see `amountVisibilityProvider`). One fixed string,
  /// so a masked value never leaks the amount's magnitude via its width.
  static const String masked = 'Rp ••••••';

  /// [idr], or the [masked] placeholder when balances are hidden. Use at
  /// masked SURFACES only (balances/summaries — see DESIGN.md "Saldo
  /// masking"); the working ledger always renders real amounts.
  static String maskedIdr(int amountMinor, {required bool visible}) {
    return visible ? idr(amountMinor) : masked;
  }

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
