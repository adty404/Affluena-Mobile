/// Pure helper for the Beranda "Tren kekayaan bersih" sparkline.
///
/// The API has no historical net-worth endpoint, but it does expose the
/// monthly cashflow trend — and net worth moves by exactly the net cashflow
/// each month. So the series is reconstructed by anchoring the CURRENT net
/// worth on the newest month and walking BACKWARD: the previous month's
/// closing net worth = this month's closing net worth minus this month's net
/// cashflow.
///
/// [monthlyNetCashflowsMinor] is ordered oldest → newest, one entry per month,
/// with the LAST entry being the current (anchor) month. The returned series
/// has the same length and order; its last element is exactly
/// [currentNetWorthMinor]. Negative cashflow months produce a rising step
/// backward (money left, so the past balance was higher).
///
/// An empty input returns an empty series (nothing to draw).
List<int> buildNetWorthSeries(
  int currentNetWorthMinor,
  List<int> monthlyNetCashflowsMinor,
) {
  if (monthlyNetCashflowsMinor.isEmpty) return const [];
  final series = List<int>.filled(monthlyNetCashflowsMinor.length, 0);
  series[series.length - 1] = currentNetWorthMinor;
  for (var i = series.length - 1; i > 0; i--) {
    series[i - 1] = series[i] - monthlyNetCashflowsMinor[i];
  }
  return series;
}
