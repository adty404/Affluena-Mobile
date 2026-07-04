import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/application/budget_controller.dart';
import '../../budgets/presentation/budget_detail_screen.dart';
import '../../calendar/application/calendar_providers.dart';
import '../../dashboard/application/dashboard_home_controller.dart';
import '../../insights/application/category_breakdown_providers.dart';
import '../../insights/application/insights_controller.dart';
import '../../redesign/presentation/activity_feed_screen.dart';
import '../../redesign/presentation/room_detail_screen.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../wallets/application/wallet_detail_controller.dart';
import '../../wallets/application/wallets_controller.dart';

/// Every provider that must refresh after a money move — wallet balances,
/// dashboard/analytics/budgets, AND the transaction-list surfaces that are NOT
/// owned by the main [transactionsControllerProvider] (which reloads itself).
/// Single source of truth shared by both the [Ref] and [WidgetRef] extensions
/// so the two lists can never drift apart and reintroduce stale-data bugs.
///
/// Family providers (e.g. [walletDetailProvider], [walletTransactionsProvider])
/// are listed once — invalidating a family without an argument refreshes every
/// currently-alive instance. The element type is inferred as `ProviderOrFamily`
/// (not publicly exported, so it can't be spelled here); every entry is a valid
/// argument to `invalidate`.
final _balanceProviders = [
  walletListProvider,
  walletDetailProvider,
  walletAnalyticsProvider,
  dashboardCashflowTrendProvider,
  dashboardExpenseDistributionProvider,
  dashboardForecastProvider,
  budgetControllerProvider,
  // The calendar month grid + any open day sheet re-aggregate from the ledger.
  calendarMonthProvider,
  // Standalone transaction-list surfaces the main ledger controller doesn't own:
  // the cross-wallet Aktivitas feed and each room/wallet detail's list. Without
  // these, a quick-add (or any non-ledger mutation) leaves them showing a stale
  // list even though balances updated. The Aktivitas feed is now an
  // autoDispose.family keyed on the feed's date/category/wallet filter — listing
  // the family base invalidates every currently-alive keyed instance.
  recentActivityProvider,
  walletTransactionsProvider,
  // The budget-detail "Transaksi" list (per category+month). A FutureProvider
  // family — listing it bare refreshes every currently-alive keyed instance.
  categoryTransactionsProvider,
  // The Wawasan "Ke mana perginya uangmu?" breakdown chart (autoDispose.family).
  // No-op when the tab is closed; refreshes the live instance while it's mounted.
  categoryBreakdownProvider,
  // The Wawasan per-category transactions screen (autoDispose.family) opened by
  // tapping a breakdown row — same lifecycle: refreshes only its live instance.
  categoryTransactionsInRangeProvider,
  // The legacy Laporan/Wawasan controller (non-autoDispose Notifier). It never
  // auto-refreshed on a money move, so it went stale across reopen; invalidating
  // re-runs its Future.microtask(load).
  insightsControllerProvider,
];

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
    for (final provider in _balanceProviders) {
      invalidate(provider);
    }
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
    for (final provider in _balanceProviders) {
      invalidate(provider);
    }
  }

  void invalidateFinancialData() {
    invalidateBalances();
    invalidate(transactionsControllerProvider);
  }
}
