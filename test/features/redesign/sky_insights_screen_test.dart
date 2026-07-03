import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/application/category_tag_management_controller.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/dashboard/application/dashboard_home_controller.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/sky_insights_screen.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _trend = CashflowTrendResponse(
  trend: [
    CashflowTrendPoint(
      month: '2026-05',
      incomeMinor: 9500000,
      expenseMinor: 3100000,
      cashflowMinor: 6400000,
    ),
    CashflowTrendPoint(
      month: '2026-06',
      incomeMinor: 9500000,
      expenseMinor: 3200000,
      cashflowMinor: 6300000,
    ),
  ],
);

const _distribution = ExpenseDistributionResponse(
  distribution: [
    ExpenseDistribution(
      categoryId: 'c1',
      categoryName: 'Makan & Minum',
      amountMinor: 1850000,
      percentage: 40,
    ),
  ],
);

const _forecast = DashboardForecast(
  currentExpenseMinor: 1800000,
  dailyAverageMinor: 90000,
  forecastedExpenseMinor: 3200000,
  budgetLimitMinor: 4000000,
  status: ForecastStatus.safe,
);

// Categories for the headline breakdown card.
const _food = Category(
  id: 'c-food',
  userId: 'u1',
  name: 'Makanan',
  type: CategoryType.expense,
  icon: 'food',
  color: '#2E8B57',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
const _salary = Category(
  id: 'c-salary',
  userId: 'u1',
  name: 'Gaji',
  type: CategoryType.income,
  icon: 'salary',
  color: '#E0A23B',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

class _StubCategoriesController extends CategoryTagManagementController {
  @override
  CategoryTagManagementState build() =>
      const CategoryTagManagementState(categories: [_food, _salary]);
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  _FakeTransactionRepository(this.transactions);

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
    final page = (offset ?? 0) == 0 ? transactions : const <Transaction>[];
    return TransactionListResponse(
      transactions: page,
      pagination: Pagination(
        total: transactions.length,
        limit: limit ?? 200,
        offset: offset ?? 0,
      ),
    );
  }
}

Transaction _tx({
  required String id,
  required TransactionType type,
  required int amountMinor,
  required String categoryId,
}) {
  final now = DateTime.now();
  final at = '${now.year}-${now.month.toString().padLeft(2, '0')}-15T04:00:00Z';
  return Transaction(
    id: id,
    userId: 'u1',
    type: type,
    walletId: 'w1',
    categoryId: categoryId,
    amountMinor: amountMinor,
    tagIds: const [],
    transactionAt: at,
    note: '',
    createdAt: at,
    updatedAt: at,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  List<Transaction>? transactions,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = _FakeTransactionRepository(
    transactions ??
        [
          _tx(
            id: 'e1',
            type: TransactionType.expense,
            amountMinor: 300000,
            categoryId: 'c-food',
          ),
          _tx(
            id: 'i1',
            type: TransactionType.income,
            amountMinor: 8000000,
            categoryId: 'c-salary',
          ),
        ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repo),
        categoryTagManagementControllerProvider.overrideWith(
          _StubCategoriesController.new,
        ),
        dashboardCashflowTrendProvider.overrideWith((ref) async => _trend),
        dashboardExpenseDistributionProvider.overrideWith(
          (ref) async => _distribution,
        ),
        dashboardForecastProvider.overrideWith((ref) async => _forecast),
      ],
      child: const MaterialApp(home: SkyInsightsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the headline breakdown + three analytics sections', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Wawasan'), findsOneWidget);
    expect(find.text('Ke mana uang?'), findsOneWidget);
    expect(find.text('Arus kas'), findsOneWidget);
    expect(find.text('Perkiraan bulan ini'), findsOneWidget);
  });

  testWidgets('shows the forecast status', (tester) async {
    await _pump(tester);

    expect(find.text('Rp 3.200.000'), findsOneWidget); // forecasted expense
    expect(find.text('Aman, di bawah budget'), findsOneWidget); // safe status
  });

  testWidgets('breakdown defaults to expense and toggles to income', (
    tester,
  ) async {
    await _pump(tester);

    // Expense selected by default: the expense category row + total show. The
    // single food expense is the whole month total, so "Rp 300.000" appears
    // twice (the card total + the row amount).
    expect(find.text('Total pengeluaran'), findsOneWidget);
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Rp 300.000'), findsNWidgets(2));
    // The income category is not rendered while expense is selected.
    expect(find.text('Gaji'), findsNothing);

    // Toggle to Pemasukan → the income category row + total show.
    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();

    expect(find.text('Total pemasukan'), findsOneWidget);
    expect(find.text('Gaji'), findsOneWidget);
    expect(find.text('Rp 8.000.000'), findsNWidgets(2));
    expect(find.text('Makanan'), findsNothing);
  });

  testWidgets('breakdown shows an empty state when the type has no data', (
    tester,
  ) async {
    // Only an income transaction: the expense breakdown is empty.
    await _pump(
      tester,
      transactions: [
        _tx(
          id: 'i1',
          type: TransactionType.income,
          amountMinor: 8000000,
          categoryId: 'c-salary',
        ),
      ],
    );

    expect(find.text('Belum ada pengeluaran'), findsOneWidget);

    await tester.tap(find.text('Pemasukan'));
    await tester.pumpAndSettle();
    expect(find.text('Gaji'), findsOneWidget);
  });
}
