import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:affluena_mobile/app/router.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/budgets/data/budget_repository.dart';
import 'package:affluena_mobile/features/budgets/presentation/budget_screen.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/debts/data/debt_repository.dart';
import 'package:affluena_mobile/features/debts/presentation/debt_screen.dart';
import 'package:affluena_mobile/features/goals/data/goal_repository.dart';
import 'package:affluena_mobile/features/goals/presentation/goal_screen.dart';
import 'package:affluena_mobile/features/insights/application/insights_controller.dart';
import 'package:affluena_mobile/features/insights/data/insights_repository.dart';
import 'package:affluena_mobile/features/insights/presentation/insights_screen.dart';
import 'package:affluena_mobile/features/recurring/data/recurring_repository.dart';
import 'package:affluena_mobile/features/recurring/presentation/recurring_screen.dart';
import 'package:affluena_mobile/features/trackers/data/tracker_repository.dart';
import 'package:affluena_mobile/features/trackers/presentation/tracker_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/auth_test_helpers.dart';
import '../budgets/budget_screen_test.dart' as budget_fakes;
import '../debts/debt_screen_test.dart' as debt_fakes;
import '../goals/goal_screen_test.dart' as goal_fakes;
import '../insights/insights_screen_test.dart' as insight_fakes;
import '../recurring/recurring_screen_test.dart' as recurring_fakes;
import '../trackers/tracker_screen_test.dart' as tracker_fakes;

void main() {
  testWidgets('More exposes every planning and insight module entry', (
    tester,
  ) async {
    await tester.pumpWidget(_navigationApp(authenticated: true));
    await tester.pumpAndSettle();
    await _openMore(tester);

    for (final scenario in _navigationScenarios) {
      await _expectSettingsEntry(tester, scenario.entry);
    }
  });

  testWidgets('authenticated module locations open module surfaces', (
    tester,
  ) async {
    await tester.pumpWidget(_navigationApp(authenticated: true));
    await tester.pumpAndSettle();

    final router = _router(tester);
    for (final scenario in _navigationScenarios) {
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
      InsightsScreen.location(InsightTab.rules),
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    }
  });
}

Widget _navigationApp({required bool authenticated}) {
  return authTestApp(
    tokenStore: authenticated ? authenticatedTokenStore() : MemoryTokenStore(),
    authRepository: FakeAuthRepository(),
    walletRepository: const _NavigationWalletRepository(),
    categoryRepository: const _NavigationCategoryRepository(),
    extraOverrides: [
      budgetRepositoryProvider.overrideWithValue(
        budget_fakes.TestBudgetRepository(),
      ),
      debtRepositoryProvider.overrideWithValue(debt_fakes.TestDebtRepository()),
      trackerRepositoryProvider.overrideWithValue(
        tracker_fakes.TestTrackerRepository(),
      ),
      recurringRepositoryProvider.overrideWithValue(
        recurring_fakes.TestRecurringRepository(),
      ),
      goalRepositoryProvider.overrideWithValue(goal_fakes.TestGoalRepository()),
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
  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();
  expect(find.text('Profile'), findsOneWidget);
}

Future<void> _expectSettingsEntry(WidgetTester tester, String entry) async {
  await _expectVisibleText(tester, entry);
}

Future<void> _expectVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      280,
      scrollable: find.byType(Scrollable).first,
    );
  }
  expect(finder, findsAtLeastNWidgets(1));
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

final _navigationScenarios = [
  _NavigationScenario(
    entry: 'Budgets',
    location: BudgetScreen.path,
    expected: 'Category budgets',
  ),
  _NavigationScenario(
    entry: 'Debt & Tracker',
    location: DebtScreen.path,
    expected: 'Debts',
  ),
  _NavigationScenario(
    entry: 'Installments & Subscriptions',
    location: TrackerScreen.path,
    expected: 'Trackers',
  ),
  _NavigationScenario(
    entry: 'Recurring',
    location: RecurringScreen.path,
    expected: 'Rules',
  ),
  _NavigationScenario(
    entry: 'Goals',
    location: GoalScreen.path,
    expected: 'Saving goals',
  ),
  _NavigationScenario(
    entry: 'Reports & Exports',
    location: InsightsScreen.location(InsightTab.exports),
    expected: 'Transaction CSV',
  ),
  _NavigationScenario(
    entry: 'Alerts & Activity',
    location: InsightsScreen.location(InsightTab.alerts),
    expected: 'Food limit reached',
  ),
  _NavigationScenario(
    entry: 'Notification rules',
    location: InsightsScreen.location(InsightTab.rules),
    expected: 'Budget alerts',
  ),
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
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return _mainWallet;
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
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return _categories.firstWhere((category) => category.id == id);
  }
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
