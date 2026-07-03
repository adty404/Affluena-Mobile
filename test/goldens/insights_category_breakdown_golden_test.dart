@Tags(['golden'])
library;

import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/features/categories/application/category_tag_management_controller.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/dashboard/application/dashboard_home_controller.dart';
import 'package:affluena_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:affluena_mobile/features/redesign/presentation/sky_insights_screen.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden (design-snapshot) of the Wawasan headline "Ke mana uang bulan ini?"
/// category-breakdown card in its default (Pengeluaran) state: the segmented
/// toggle, the total, and the ranked category rows (icon tile + name + amount +
/// proportion bar + %). Text renders as the placeholder test font, so this is a
/// layout drift detector, not a pixel match.

const _trend = CashflowTrendResponse(trend: []);
const _distribution = ExpenseDistributionResponse(distribution: []);
const _forecast = DashboardForecast(
  currentExpenseMinor: 0,
  dailyAverageMinor: 0,
  forecastedExpenseMinor: 0,
  budgetLimitMinor: 0,
  status: ForecastStatus.safe,
);

const _food = Category(
  id: 'c-food',
  userId: 'u1',
  name: 'Makanan',
  type: CategoryType.expense,
  icon: 'food',
  color: '#C2553F',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
const _transport = Category(
  id: 'c-transport',
  userId: 'u1',
  name: 'Transportasi',
  type: CategoryType.expense,
  icon: 'transport',
  color: '#3E72B8',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);
const _bills = Category(
  id: 'c-bills',
  userId: 'u1',
  name: 'Tagihan',
  type: CategoryType.expense,
  icon: 'bills',
  color: '#7C5BC2',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

class _StubCategoriesController extends CategoryTagManagementController {
  @override
  CategoryTagManagementState build() =>
      const CategoryTagManagementState(categories: [_food, _transport, _bills]);
}

class _FakeRepo extends Fake implements TransactionRepository {
  _FakeRepo(this.transactions);
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

Transaction _tx(String id, int amount, String categoryId, String at) {
  return Transaction(
    id: id,
    userId: 'u1',
    type: TransactionType.expense,
    walletId: 'w1',
    categoryId: categoryId,
    amountMinor: amount,
    tagIds: const [],
    transactionAt: at,
    note: '',
    createdAt: at,
    updatedAt: at,
  );
}

void main() {
  setUp(() {
    // The insights providers touch secure storage / Dio through the overridden
    // repos; stub the secure-storage channel so nothing throws in the harness.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  testWidgets('insights category breakdown golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime.now();
    String at(int day) {
      final m = now.month.toString().padLeft(2, '0');
      final d = day.toString().padLeft(2, '0');
      return '${now.year}-$m-${d}T04:00:00Z';
    }

    final repo = _FakeRepo([
      _tx('t1', 1250000, 'c-food', at(3)),
      _tx('t2', 640000, 'c-transport', at(5)),
      _tx('t3', 420000, 'c-bills', at(8)),
    ]);

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
    // The theme defaults to Tinta light via the app; pump until the async
    // breakdown settles.
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/insights_category_breakdown.png'),
    );
  });
}
