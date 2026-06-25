import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../categories/data/category_models.dart';
import '../../categories/data/category_repository.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../wallets/data/wallet_models.dart';
import '../../wallets/data/wallet_repository.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

final dashboardHomeProvider = FutureProvider.autoDispose<DashboardHome>((
  ref,
) async {
  final month = AffluenaDateFormatter.monthKey(DateTime.now());
  final responses = await Future.wait<Object>([
    ref.read(dashboardRepositoryProvider).summary(month: month),
    ref
        .read(transactionRepositoryProvider)
        .listTransactions(limit: 3, offset: 0, sort: 'transaction_at_desc'),
    ref.read(walletRepositoryProvider).listWallets(limit: 100, offset: 0),
    ref.read(categoryRepositoryProvider).listCategories(limit: 100, offset: 0),
  ]);

  final summary = responses[0] as DashboardSummary;
  final transactions = responses[1] as TransactionListResponse;
  final wallets = responses[2] as WalletListResponse;
  final categories = responses[3] as CategoryListResponse;

  return DashboardHome(
    summary: summary,
    recentTransactions: transactions.transactions,
    walletNames: {for (final wallet in wallets.wallets) wallet.id: wallet.name},
    categoryNames: {
      for (final category in categories.categories) category.id: category.name,
    },
  );
});

class DashboardHome {
  const DashboardHome({
    required this.summary,
    required this.recentTransactions,
    required this.walletNames,
    required this.categoryNames,
  });

  final DashboardSummary summary;
  final List<Transaction> recentTransactions;
  final Map<String, String> walletNames;
  final Map<String, String> categoryNames;

  bool get isEmpty {
    return summary.netWorthMinor == 0 &&
        summary.monthlyIncomeMinor == 0 &&
        summary.monthlyExpenseMinor == 0 &&
        summary.monthlyCashflowMinor == 0 &&
        summary.budget.limitMinor == 0 &&
        summary.upcomingSubscriptions.isEmpty &&
        summary.upcomingInstallments.isEmpty &&
        summary.upcomingDebts.isEmpty &&
        recentTransactions.isEmpty;
  }

  String walletName(String walletId) {
    return walletNames[walletId] ?? 'Unknown wallet';
  }

  String categoryName(Transaction transaction) {
    if (transaction.type == TransactionType.transfer) return 'Transfer';
    final categoryId = transaction.categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      return transaction.type == TransactionType.income
          ? 'Income'
          : 'Uncategorized';
    }
    return categoryNames[categoryId] ?? 'Uncategorized';
  }
}

/// Bucket size for the cashflow trend chart. Toggled from the dashboard.
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
final dashboardForecastProvider =
    FutureProvider.autoDispose<DashboardForecast>((ref) async {
      final month = AffluenaDateFormatter.monthKey(DateTime.now());
      return ref.read(dashboardRepositoryProvider).forecast(month: month);
    });
