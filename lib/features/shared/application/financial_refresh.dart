import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/application/budget_controller.dart';
import '../../dashboard/application/dashboard_home_controller.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../wallets/application/wallet_detail_controller.dart';
import '../../wallets/application/wallets_controller.dart';

/// Invalidates every provider whose data depends on wallet balances or the
/// transaction ledger.
///
/// Call this after ANY mutation that moves money — create/edit/delete a
/// transaction, execute a quick-entry template, split a bill, pay a debt,
/// pay an installment/subscription, run a recurring rule, contribute to a
/// goal — so the wallet balances, dashboard, analytics, and budgets the user
/// sees stay consistent with the server instead of showing stale numbers.
extension FinancialRefresh on Ref {
  /// Invalidate wallet balances + dashboard + budgets, but NOT the transaction
  /// list. Use this from the transaction controller itself — it refreshes its
  /// own list via load(); invalidating its own provider here would dispose the
  /// controller mid-mutation.
  void invalidateBalances() {
    invalidate(walletListProvider);
    // Family providers — invalidating without an argument refreshes every
    // currently-alive instance.
    invalidate(walletDetailProvider);
    invalidate(walletAnalyticsProvider);
    invalidate(dashboardHomeProvider);
    invalidate(dashboardCashflowTrendProvider);
    invalidate(dashboardExpenseDistributionProvider);
    invalidate(dashboardForecastProvider);
    invalidate(budgetControllerProvider);
  }

  /// Balances + the transaction list. Use this from controllers OTHER than the
  /// transaction controller (debt/tracker/quick-entry/recurring/goal/split):
  /// they create transactions but do not own the transaction list.
  void invalidateFinancialData() {
    invalidateBalances();
    invalidate(transactionsControllerProvider);
  }
}

/// WidgetRef variant for widgets/sheets that mutate money directly (e.g. the
/// wallet balance-adjust sheet) rather than going through a controller.
extension FinancialRefreshWidget on WidgetRef {
  void invalidateBalances() {
    invalidate(walletListProvider);
    invalidate(walletDetailProvider);
    invalidate(walletAnalyticsProvider);
    invalidate(dashboardHomeProvider);
    invalidate(dashboardCashflowTrendProvider);
    invalidate(dashboardExpenseDistributionProvider);
    invalidate(dashboardForecastProvider);
    invalidate(budgetControllerProvider);
  }

  void invalidateFinancialData() {
    invalidateBalances();
    invalidate(transactionsControllerProvider);
  }
}
