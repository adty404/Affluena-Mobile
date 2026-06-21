import 'dart:async';

import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:affluena_mobile/core/api/api_error.dart';
import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/core/storage/secure_token_store.dart';
import 'package:affluena_mobile/features/auth/data/auth_repository.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/auth_test_helpers.dart';

void main() {
  testWidgets('shows loading state while dashboard request is pending', (
    tester,
  ) async {
    final pendingSummary = Completer<DashboardSummary>();

    await tester.pumpWidget(
      dashboardTestApp(
        dashboardRepository: FakeDashboardRepository(
          summaryHandler: () => pendingSummary.future,
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Loading dashboard'));

    expect(find.text('Loading dashboard'), findsOneWidget);

    pendingSummary.complete(seededSummary);
    await tester.pumpAndSettle();
  });

  testWidgets('renders seeded summary and resolved recent transaction names', (
    tester,
  ) async {
    await tester.pumpWidget(dashboardTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Rp 16.370.000'), findsOneWidget);
    expect(find.text('Rp 21.000.000'), findsOneWidget);
    expect(find.text('Budget 72% used'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lunch meeting'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lunch meeting'), findsOneWidget);
    expect(find.text('Food & Dining · GoPay · 21 Jun 2026'), findsOneWidget);
    expect(find.textContaining('22222222-2222'), findsNothing);
    expect(find.textContaining('44444444-4444'), findsNothing);
  });

  testWidgets('renders mobile empty state for users without dashboard data', (
    tester,
  ) async {
    await tester.pumpWidget(
      dashboardTestApp(
        dashboardRepository: const FakeDashboardRepository(
          summaryResponse: emptySummary,
        ),
        transactionRepository: const FakeTransactionRepository(
          transactions: [],
        ),
        walletRepository: const FakeWalletRepository(wallets: []),
        categoryRepository: const FakeCategoryRepository(categories: []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No activity yet'), findsOneWidget);
    expect(
      find.text(
        'Add your first wallet or transaction to start filling this dashboard.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('No recent transactions yet.'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No recent transactions yet.'), findsOneWidget);
  });

  testWidgets('renders error state and retries dashboard request', (
    tester,
  ) async {
    var calls = 0;
    var shouldFail = true;

    await tester.pumpWidget(
      dashboardTestApp(
        dashboardRepository: FakeDashboardRepository(
          summaryHandler: () async {
            calls += 1;
            if (shouldFail) {
              throw const ApiException(message: 'dashboard temporarily down');
            }
            return seededSummary;
          },
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('Dashboard unavailable'));

    expect(find.text('Dashboard unavailable'), findsOneWidget);
    expect(find.text('dashboard temporarily down'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.byKey(const Key('dashboard-retry-button')));
    await tester.pumpAndSettle();

    expect(calls, greaterThanOrEqualTo(2));
    expect(find.text('Rp 16.370.000'), findsOneWidget);
  });
}

Widget dashboardTestApp({
  DashboardRepository dashboardRepository = const FakeDashboardRepository(),
  TransactionRepository transactionRepository =
      const FakeTransactionRepository(),
  WalletRepository walletRepository = const FakeWalletRepository(),
  CategoryRepository categoryRepository = const FakeCategoryRepository(),
}) {
  return ProviderScope(
    overrides: [
      secureTokenStoreProvider.overrideWithValue(authenticatedTokenStore()),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
      transactionRepositoryProvider.overrideWithValue(transactionRepository),
      walletRepositoryProvider.overrideWithValue(walletRepository),
      categoryRepositoryProvider.overrideWithValue(categoryRepository),
    ],
    child: const AffluenaApp(),
  );
}

class FakeDashboardRepository implements DashboardRepository {
  const FakeDashboardRepository({
    this.summaryResponse = seededSummary,
    this.summaryHandler,
  });

  final DashboardSummary summaryResponse;
  final Future<DashboardSummary> Function()? summaryHandler;

  @override
  Future<DashboardSummary> summary({String? month}) {
    return summaryHandler?.call() ?? Future.value(summaryResponse);
  }

  @override
  Future<CashflowTrendResponse> cashflowTrend({int? months}) {
    throw UnimplementedError();
  }

  @override
  Future<ExpenseDistributionResponse> expenseDistribution({String? month}) {
    throw UnimplementedError();
  }

  @override
  Future<DashboardForecast> forecast({String? month}) {
    throw UnimplementedError();
  }
}

class FakeTransactionRepository implements TransactionRepository {
  const FakeTransactionRepository({
    this.transactions = const [seededTransaction],
  });

  final List<Transaction> transactions;

  @override
  Future<TransactionListResponse> listTransactions({
    TransactionType? type,
    String? walletId,
    String? categoryId,
    String? tagId,
    String? from,
    String? to,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return TransactionListResponse(
      transactions: transactions,
      pagination: Pagination(
        total: transactions.length,
        limit: limit ?? transactions.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    return transactions.firstWhere((transaction) => transaction.id == id);
  }

  @override
  Future<void> deleteTransaction(String id) async {}
}

class FakeWalletRepository implements WalletRepository {
  const FakeWalletRepository({this.wallets = const [seededWallet]});

  final List<Wallet> wallets;

  @override
  Future<WalletListResponse> listWallets({
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return WalletListResponse(
      wallets: wallets,
      pagination: Pagination(
        total: wallets.length,
        limit: limit ?? wallets.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Wallet> createWallet(WalletRequest request) async {
    return wallets.first;
  }

  @override
  Future<Wallet> updateWallet(String id, WalletRequest request) async {
    return wallets.firstWhere((wallet) => wallet.id == id);
  }
}

class FakeCategoryRepository implements CategoryRepository {
  const FakeCategoryRepository({this.categories = const [seededCategory]});

  final List<Category> categories;

  @override
  Future<CategoryListResponse> listCategories({
    CategoryType? type,
    int? limit,
    int? offset,
    String? sort,
  }) async {
    return CategoryListResponse(
      categories: categories,
      pagination: Pagination(
        total: categories.length,
        limit: limit ?? categories.length,
        offset: offset ?? 0,
      ),
    );
  }

  @override
  Future<Category> createCategory(CategoryRequest request) async {
    return categories.first;
  }

  @override
  Future<Category> updateCategory(String id, CategoryRequest request) async {
    return categories.firstWhere((category) => category.id == id);
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 10,
}) async {
  for (var i = 0; i < attempts; i += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

const seededSummary = DashboardSummary(
  month: '2026-06',
  netWorthMinor: 16370000,
  monthlyIncomeMinor: 21000000,
  monthlyExpenseMinor: 3300000,
  monthlyCashflowMinor: 17700000,
  budget: BudgetSummary(
    limitMinor: 1000000,
    spentMinor: 720000,
    remainingMinor: 280000,
    usagePercent: 72,
  ),
  upcomingSubscriptions: [],
  upcomingInstallments: [],
  upcomingDebts: [],
);

const emptySummary = DashboardSummary(
  month: '2026-06',
  netWorthMinor: 0,
  monthlyIncomeMinor: 0,
  monthlyExpenseMinor: 0,
  monthlyCashflowMinor: 0,
  budget: BudgetSummary(
    limitMinor: 0,
    spentMinor: 0,
    remainingMinor: 0,
    usagePercent: 0,
  ),
  upcomingSubscriptions: [],
  upcomingInstallments: [],
  upcomingDebts: [],
);

const seededWalletId = '22222222-2222-2222-2222-222222220003';
const seededCategoryId = '44444444-4444-4444-4444-444444440001';

const seededWallet = Wallet(
  id: seededWalletId,
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 320000,
  color: 'green',
  description: 'Daily wallet',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seededCategory = Category(
  id: seededCategoryId,
  userId: '11111111-1111-1111-1111-111111111111',
  name: 'Food & Dining',
  type: CategoryType.expense,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

const seededTransaction = Transaction(
  id: '66666666-6666-6666-6666-666666660001',
  userId: '11111111-1111-1111-1111-111111111111',
  type: TransactionType.expense,
  walletId: seededWalletId,
  categoryId: seededCategoryId,
  amountMinor: 125000,
  tagIds: [],
  transactionAt: '2026-06-21T10:00:00Z',
  note: 'Lunch meeting',
  createdAt: '2026-06-21T10:00:00Z',
  updatedAt: '2026-06-21T10:00:00Z',
);
