import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:affluena_mobile/app/router.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/budgets/presentation/budget_screen.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/categories/presentation/category_tag_management_screen.dart';
import 'package:affluena_mobile/features/debts/data/debt_repository.dart';
import 'package:affluena_mobile/features/debts/presentation/debt_screen.dart';
import 'package:affluena_mobile/features/goals/presentation/goal_screen.dart';
import 'package:affluena_mobile/features/insights/application/insights_controller.dart';
import 'package:affluena_mobile/features/insights/data/insights_repository.dart';
import 'package:affluena_mobile/features/insights/presentation/audit_log_screen.dart';
import 'package:affluena_mobile/features/insights/presentation/insights_screen.dart';
import 'package:affluena_mobile/features/quick_entry/presentation/quick_entry_screen.dart';
import 'package:affluena_mobile/features/quick_entry/presentation/quick_entry_templates_screen.dart';
import 'package:affluena_mobile/features/recurring/presentation/recurring_screen.dart';
import 'package:affluena_mobile/features/redesign/presentation/redesign_shell.dart';
import 'package:affluena_mobile/features/settings/presentation/settings_screen.dart';
import 'package:affluena_mobile/features/trackers/presentation/tracker_screen.dart';
import 'package:affluena_mobile/features/transactions/presentation/split_bill_screen.dart';
import 'package:affluena_mobile/features/transactions/presentation/transactions_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallet_detail_screen.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallet_sharing_screen.dart';
import 'package:affluena_mobile/features/wallets/presentation/wallets_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/auth_test_helpers.dart';
import '../budgets/budget_screen_test.dart' as budget_fakes;
import '../debts/debt_screen_test.dart' as debt_fakes;
import '../goals/goal_screen_test.dart' as goal_fakes;
import '../insights/insights_screen_test.dart' as insight_fakes;
import '../recurring/recurring_screen_test.dart' as recurring_fakes;
import '../trackers/tracker_screen_test.dart' as tracker_fakes;

void main() {
  // DatePickerField (used by the split-bill surface) formats dates with the
  // id_ID locale, which must be initialized before the widgets build.
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('More exposes every planning and insight module entry', (
    tester,
  ) async {
    await tester.pumpWidget(_navigationApp(authenticated: true));
    await tester.pumpAndSettle();
    await _openMore(tester);

    for (final scenario in _settingsNavigationScenarios) {
      await _expectSettingsEntry(tester, scenario.entry);
    }
  });

  testWidgets('authenticated module locations open module surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(_navigationApp(authenticated: true));
    await tester.pumpAndSettle();

    final router = _router(tester);
    for (final scenario in [
      ..._settingsNavigationScenarios,
      ..._directNavigationScenarios,
    ]) {
      router.go(scenario.location);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      await _expectVisibleText(tester, scenario.expected);
    }
  });

  testWidgets('unauthenticated module deep links redirect to login', (
    tester,
  ) async {
    await tester.pumpWidget(_navigationApp(authenticated: false));
    await tester.pumpAndSettle();

    final router = _router(tester);
    for (final location in [
      BudgetScreen.path,
      DebtScreen.path,
      TrackerScreen.path,
      RecurringScreen.path,
      GoalScreen.path,
      CategoryTagManagementScreen.path,
      QuickEntryTemplatesScreen.path,
      SplitBillScreen.path,
      AuditLogScreen.path,
      InsightsScreen.location(InsightTab.rules),
      WalletDetailScreen.location('wallet-main'),
      WalletSharingScreen.location('wallet-main'),
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    }
  });

  testWidgets('parity surfaces never render raw resource ids', (tester) async {
    await tester.pumpWidget(_navigationApp(authenticated: true));
    await tester.pumpAndSettle();

    final router = _router(tester);
    for (final location in _rawIdSmokeLocations) {
      router.go(location);
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      await _expectNoRawResourceIds(tester);
    }
  });
}

Widget _navigationApp({required bool authenticated}) {
  return authTestApp(
    tokenStore: authenticated ? authenticatedTokenStore() : MemoryTokenStore(),
    authRepository: FakeAuthRepository(),
    walletRepository: const _NavigationWalletRepository(),
    categoryRepository: const _NavigationCategoryRepository(),
    goalRepository: goal_fakes.TestGoalRepository(),
    budgetRepository: budget_fakes.TestBudgetRepository(),
    trackerRepository: tracker_fakes.TestTrackerRepository(),
    recurringRepository: recurring_fakes.TestRecurringRepository(),
    extraOverrides: [
      debtRepositoryProvider.overrideWithValue(debt_fakes.TestDebtRepository()),
      insightsRepositoryProvider.overrideWithValue(
        insight_fakes.TestInsightsRepository(),
      ),
    ],
  );
}

GoRouter _router(WidgetTester tester) {
  final context = tester.element(find.byType(AffluenaApp));
  return ProviderScope.containerOf(context).read(appRouterProvider);
}

Future<void> _openMore(WidgetTester tester) async {
  final moreTab = find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text('More'),
  );
  if (moreTab.evaluate().isNotEmpty) {
    await tester.tap(moreTab);
  }
  await tester.pumpAndSettle();
  if (find.byType(SettingsScreen).evaluate().isEmpty) {
    _router(tester).go(SettingsScreen.path);
    await tester.pumpAndSettle();
  }
  expect(find.byType(SettingsScreen), findsOneWidget);
  expect(find.text('Pengaturan'), findsOneWidget);
}

Future<void> _expectSettingsEntry(WidgetTester tester, String entry) async {
  await _expectVisibleText(tester, entry);
}

Future<void> _expectVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  for (var attempt = 0; attempt < 10; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      expect(finder, findsAtLeastNWidgets(1));
      return;
    }
    final listView = find.byType(ListView);
    expect(listView, findsWidgets);
    await tester.drag(listView.first, const Offset(0, -320));
    await tester.pumpAndSettle();
  }
  expect(finder, findsAtLeastNWidgets(1));
}

Future<void> _expectNoRawResourceIds(WidgetTester tester) async {
  for (var attempt = 0; attempt < 6; attempt += 1) {
    for (final token in _rawResourceIdTokens) {
      expect(find.textContaining(token), findsNothing);
    }
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isEmpty) return;
    await tester.drag(scrollable.first, const Offset(0, -320));
    await tester.pumpAndSettle();
  }
}

class _NavigationScenario {
  const _NavigationScenario({
    required this.entry,
    required this.location,
    required this.expected,
  });

  final String entry;
  final String location;
  final String expected;
}

final _settingsNavigationScenarios = [
  _NavigationScenario(
    entry: 'Dompet',
    location: WalletsScreen.path,
    expected: 'Dompet',
  ),
  _NavigationScenario(
    entry: 'Transaksi',
    location: TransactionsScreen.path,
    expected: 'Transaksi',
  ),
  _NavigationScenario(
    entry: 'Template catat cepat',
    location: QuickEntryTemplatesScreen.path,
    expected: 'Template catat cepat',
  ),
  _NavigationScenario(
    entry: 'Kategori',
    location: CategoryTagManagementScreen.path,
    expected: 'Kategori',
  ),
  _NavigationScenario(
    entry: 'Anggaran',
    location: BudgetScreen.path,
    expected: 'Anggaran kategori',
  ),
  _NavigationScenario(
    entry: 'Cicilan & Langganan',
    location: TrackerScreen.path,
    expected: 'Cicilan & Langganan',
  ),
  _NavigationScenario(
    entry: 'Aturan berulang',
    location: RecurringScreen.path,
    expected: 'Aturan',
  ),
  _NavigationScenario(
    entry: 'Target tabungan',
    location: GoalScreen.path,
    expected: 'Target tabungan',
  ),
  _NavigationScenario(
    entry: 'Laporan',
    location: InsightsScreen.location(InsightTab.reports),
    // Metric label is fixture data, not a translated UI string.
    expected: 'Overview balance',
  ),
  _NavigationScenario(
    entry: 'Log audit',
    location: AuditLogScreen.path,
    expected: 'Log audit',
  ),
  _NavigationScenario(
    entry: 'Peringatan & Aktivitas',
    location: InsightsScreen.location(InsightTab.alerts),
    // Alert title is fixture data, not a translated UI string.
    expected: 'Food limit reached',
  ),
  _NavigationScenario(
    entry: 'Aturan notifikasi',
    location: InsightsScreen.location(InsightTab.rules),
    // Rule title is fixture data, not a translated UI string.
    expected: 'Budget alerts',
  ),
];

final _directNavigationScenarios = [
  // Split bill and Debt are hidden from the More menu but their routes still
  // resolve (kept reachable via deep link), so cover them here, not in the
  // settings-menu list above.
  _NavigationScenario(
    entry: 'Bagi tagihan',
    location: SplitBillScreen.path,
    expected: 'Bagi tagihan',
  ),
  _NavigationScenario(
    entry: 'Utang',
    location: DebtScreen.path,
    expected: 'Utang',
  ),
  _NavigationScenario(
    entry: 'Detail dompet',
    location: WalletDetailScreen.location('wallet-main'),
    expected: 'Main Wallet',
  ),
  _NavigationScenario(
    entry: 'Berbagi',
    location: WalletSharingScreen.location('wallet-main'),
    expected: 'Berbagi',
  ),
];

final _rawIdSmokeLocations = [
  RedesignShell.path,
  WalletsScreen.path,
  WalletDetailScreen.location('wallet-main'),
  WalletSharingScreen.location('wallet-main'),
  QuickEntryScreen.path,
  QuickEntryTemplatesScreen.path,
  TransactionsScreen.path,
  SplitBillScreen.path,
  SettingsScreen.path,
  BudgetScreen.path,
  DebtScreen.path,
  TrackerScreen.path,
  RecurringScreen.path,
  GoalScreen.path,
  CategoryTagManagementScreen.path,
  InsightsScreen.location(InsightTab.reports),
  InsightsScreen.location(InsightTab.exports),
  InsightsScreen.location(InsightTab.alerts),
  InsightsScreen.location(InsightTab.rules),
  AuditLogScreen.path,
];

const _rawResourceIdTokens = [
  'wallet-main',
  'wallet-save',
  'wallet-goal',
  'category-food',
  'category-transport',
  'category-rent',
  'category-salary',
  '22222222-2222',
  '44444444-4444',
];

class _NavigationWalletRepository implements WalletRepository {
  const _NavigationWalletRepository();

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return const WalletListResponse(
      wallets: [_mainWallet, _savingsWallet, _goalWallet],
      pagination: Pagination(total: 3, limit: 100, offset: 0),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async => _mainWallet;

  @override
  Future<Wallet> getWallet(String id) async {
    return [
      _mainWallet,
      _savingsWallet,
      _goalWallet,
    ].firstWhere((wallet) => wallet.id == id);
  }

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return _mainWallet;
  }

  @override
  Future<void> deleteWallet(String id) async {}

  @override
  Future<WalletInviteResponse> inviteMember(
    String id,
    WalletInviteRequest request,
  ) async {
    return const WalletInviteResponse(status: WalletShareStatus.pending);
  }

  @override
  Future<WalletInviteResponse> respondInvite(
    String id,
    String memberId,
    WalletInviteResponse response,
  ) async {
    return response;
  }

  @override
  Future<WalletMembersResponse> listMembers(String id) async {
    final wallet = await getWallet(id);
    return WalletMembersResponse(members: wallet.members);
  }

  @override
  Future<WalletAnalytics> getAnalytics(String id, {String? month}) async {
    return WalletAnalytics(
      walletId: id,
      month: month ?? '2026-06',
      inflowMinor: 0,
      outflowMinor: 0,
      transactionCount: 0,
    );
  }
}

class _NavigationCategoryRepository implements CategoryRepository {
  const _NavigationCategoryRepository();

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    final filtered = type == null
        ? _categories
        : _categories.where((category) => category.type == type).toList();
    return CategoryListResponse(
      categories: filtered,
      pagination: Pagination(
        total: filtered.length,
        limit: limit ?? filtered.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    return _categories.firstWhere((category) => category.type == request.type);
  }

  @override
  Future<Category> getCategory(String id) async {
    return _categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return _categories.firstWhere((category) => category.id == id);
  }

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<void> reorderCategories(List<String> ids) async {}
}

const _mainWallet = Wallet(
  id: 'wallet-main',
  userId: 'user-1',
  name: 'Main Wallet',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 5000000,
  color: 'green',
  description: 'Primary',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _savingsWallet = Wallet(
  id: 'wallet-save',
  userId: 'user-1',
  name: 'Savings',
  type: WalletType.bank,
  currencyCode: 'IDR',
  balanceMinor: 2500000,
  color: 'green',
  description: 'Savings',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _goalWallet = Wallet(
  id: 'wallet-goal',
  userId: 'user-1',
  name: 'Emergency fund',
  type: WalletType.goal,
  currencyCode: 'IDR',
  balanceMinor: 1000000,
  color: 'blue',
  description: 'Goal',
  goalId: 'goal-1',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const _categories = [
  Category(
    id: 'category-food',
    userId: 'user-1',
    name: 'Food & Dining',
    type: CategoryType.expense,
    createdAt: '2026-06-01T00:00:00Z',
    updatedAt: '2026-06-01T00:00:00Z',
  ),
  Category(
    id: 'category-transport',
    userId: 'user-1',
    name: 'Transportation',
    type: CategoryType.expense,
    createdAt: '2026-06-01T00:00:00Z',
    updatedAt: '2026-06-01T00:00:00Z',
  ),
  Category(
    id: 'category-rent',
    userId: 'user-1',
    name: 'Rent',
    type: CategoryType.expense,
    createdAt: '2026-06-01T00:00:00Z',
    updatedAt: '2026-06-01T00:00:00Z',
  ),
  Category(
    id: 'category-salary',
    userId: 'user-1',
    name: 'Salary',
    type: CategoryType.income,
    createdAt: '2026-06-01T00:00:00Z',
    updatedAt: '2026-06-01T00:00:00Z',
  ),
];
