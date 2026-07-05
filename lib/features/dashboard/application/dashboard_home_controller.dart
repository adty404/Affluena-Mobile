import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../notifications/application/notification_scheduler.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

// The old dashboard's aggregate provider (dashboardHomeProvider/DashboardHome)
// was removed in the redesign final flip. The analytics providers below survive
// because the redesign Insights screen reuses them.

/// The dashboard summary (net worth, this month's cashflow, and the upcoming
/// installment/subscription/debt dues) powering Beranda's "Ringkasan" and
/// "Jatuh tempo terdekat" sections.
///
/// Every successful (re)fetch also hands the fresh dues to the
/// [NotificationScheduler] (`requestResync`, debounced inside the scheduler).
/// This single hook covers both required resync moments: app start/login
/// (Beranda mounts and fetches the summary) and every money mutation
/// (`invalidateBalances` lists this provider, so it re-runs while Beranda is
/// alive). On the macOS test host the scheduler is a no-op (not Android).
final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) async {
  final summary = await ref.watch(dashboardRepositoryProvider).summary();
  ref.read(notificationSchedulerProvider).requestResync(summary);
  return summary;
});

/// Twelve months of cashflow history for Beranda's "Tren kekayaan bersih"
/// sparkline. Separate from [dashboardCashflowTrendProvider] (the Wawasan
/// chart), which is keyed to the user-toggled granularity and a shorter window.
final berandaCashflowTrendProvider =
    FutureProvider.autoDispose<CashflowTrendResponse>((ref) {
      return ref.watch(dashboardRepositoryProvider).cashflowTrend(months: 12);
    });

/// Bucket size for the cashflow trend chart. Toggled from the Insights screen.
enum CashflowGranularity { month, week }

class CashflowGranularityController extends Notifier<CashflowGranularity> {
  @override
  CashflowGranularity build() => CashflowGranularity.month;

  void set(CashflowGranularity value) => state = value;
}

/// Holds the selected cashflow-trend granularity (defaults to monthly).
final dashboardCashflowGranularityProvider =
    NotifierProvider<CashflowGranularityController, CashflowGranularity>(
      CashflowGranularityController.new,
    );

/// Compact income/expense history for the trend chart. Kept independent of the
/// summary so it can show its own skeleton without blocking the balance card.
final dashboardCashflowTrendProvider =
    FutureProvider.autoDispose<CashflowTrendResponse>((ref) async {
      final granularity = ref.watch(dashboardCashflowGranularityProvider);
      final repo = ref.read(dashboardRepositoryProvider);
      return granularity == CashflowGranularity.week
          ? repo.cashflowTrend(granularity: 'week', weeks: 8)
          : repo.cashflowTrend(months: 6);
    });

class DistributionMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void set(DateTime value) => state = value;
}

/// Holds the month the "Where money went" section is filtered to (first-of-month).
final dashboardDistributionMonthProvider =
    NotifierProvider<DistributionMonthController, DateTime>(
      DistributionMonthController.new,
    );

/// Spending broken down by category for the selected month, with category names
/// already resolved by the API.
final dashboardExpenseDistributionProvider =
    FutureProvider.autoDispose<ExpenseDistributionResponse>((ref) async {
      final month = ref.watch(dashboardDistributionMonthProvider);
      return ref
          .read(dashboardRepositoryProvider)
          .expenseDistribution(month: AffluenaDateFormatter.monthKey(month));
    });

/// End-of-month spending projection used to surface an over-budget warning.
final dashboardForecastProvider = FutureProvider.autoDispose<DashboardForecast>(
  (ref) async {
    final month = AffluenaDateFormatter.monthKey(DateTime.now());
    return ref.read(dashboardRepositoryProvider).forecast(month: month);
  },
);
