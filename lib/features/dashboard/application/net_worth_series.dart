/// Pure helper for the Beranda "Tren kekayaan bersih" sparkline.
///
/// The API has no historical net-worth endpoint, but it does expose the
/// monthly cashflow trend — and net worth moves by exactly the net cashflow
/// each month. So the series is reconstructed by anchoring the CURRENT net
/// worth on the newest month and walking BACKWARD: the previous month's
/// closing net worth = this month's closing net worth minus this month's net
/// cashflow.
///
/// **Known limitation**: the cashflow trend only sees income/expense
/// transactions. Wallet INITIAL balances and `adjustment` transactions change
/// the real balance without appearing in the trend, so their amounts are
/// effectively back-propagated into every reconstructed (older) point. As an
/// interim mitigation the series is CLAMPED to start at the month the user's
/// earliest wallet was created (via [monthKeys] + [earliestWalletCreatedAt]):
/// points older than that would claim wealth existed before any wallet did,
/// so they are dropped. Within the clamped window the distortion remains — a
/// truly accurate history needs API support (per-bucket adjustment and
/// initial-balance deltas).
///
/// [monthlyNetCashflowsMinor] is ordered oldest → newest, one entry per month,
/// with the LAST entry being the current (anchor) month. The returned series
/// preserves that order; its last element is exactly [currentNetWorthMinor].
/// Negative cashflow months produce a rising step backward (money left, so
/// the past balance was higher).
///
/// [monthKeys] is the parallel list of the trend buckets' month labels — any
/// string starting `YYYY-MM` (the API may send either `2026-06` or a full
/// RFC3339 timestamp, see CLAUDE.md). [earliestWalletCreatedAt] is the
/// RFC3339 `createdAt` of the user's oldest wallet. When either is absent or
/// malformed, or the lengths mismatch, clamping is skipped (fail-open) and
/// the full series is returned.
///
/// An empty input returns an empty series (nothing to draw).
List<int> buildNetWorthSeries(
  int currentNetWorthMinor,
  List<int> monthlyNetCashflowsMinor, {
  List<String>? monthKeys,
  String? earliestWalletCreatedAt,
}) {
  if (monthlyNetCashflowsMinor.isEmpty) return const [];
  final series = List<int>.filled(monthlyNetCashflowsMinor.length, 0);
  series[series.length - 1] = currentNetWorthMinor;
  for (var i = series.length - 1; i > 0; i--) {
    series[i - 1] = series[i] - monthlyNetCashflowsMinor[i];
  }
  final start = _clampStartIndex(
    monthKeys: monthKeys,
    seriesLength: series.length,
    earliestWalletCreatedAt: earliestWalletCreatedAt,
  );
  return start == 0 ? series : series.sublist(start);
}

/// The first series index whose month is >= the earliest wallet's creation
/// month, or 0 (no clamping) when the inputs are absent, malformed, or
/// mismatched. The anchor (newest) point is always kept: even when every
/// bucket predates the wallet, the current net worth itself is real.
int _clampStartIndex({
  required List<String>? monthKeys,
  required int seriesLength,
  required String? earliestWalletCreatedAt,
}) {
  if (monthKeys == null || earliestWalletCreatedAt == null) return 0;
  if (monthKeys.length != seriesLength) return 0;
  final earliestMonth = _monthPrefix(earliestWalletCreatedAt);
  if (earliestMonth == null) return 0;
  for (var i = 0; i < monthKeys.length; i++) {
    final month = _monthPrefix(monthKeys[i]);
    if (month == null) return 0; // Malformed bucket label: fail open.
    // Same-format `YYYY-MM` strings compare correctly lexicographically.
    if (month.compareTo(earliestMonth) >= 0) return i;
  }
  return seriesLength - 1;
}

/// The `YYYY-MM` prefix of an API date/bucket label, or null when malformed.
String? _monthPrefix(String value) {
  return RegExp(r'^\d{4}-\d{2}').firstMatch(value)?.group(0);
}
