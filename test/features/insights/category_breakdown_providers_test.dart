import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/core/formatters/date_formatter.dart';
import 'package:affluena_mobile/features/categories/application/category_tag_management_controller.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/insights/application/category_breakdown_providers.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Two expense + one income category with chosen icon/color so slices resolve
// hermetically to the catalog values.
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
  CategoryTagManagementState build() => const CategoryTagManagementState(
    categories: [_food, _transport, _salary],
  );
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
    // Single page: return everything on offset 0, empty afterwards.
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
  required String transactionAt,
  String? categoryId,
}) {
  return Transaction(
    id: id,
    userId: 'u1',
    type: type,
    walletId: 'w1',
    categoryId: categoryId,
    amountMinor: amountMinor,
    tagIds: const [],
    transactionAt: transactionAt,
    note: '',
    createdAt: transactionAt,
    updatedAt: transactionAt,
  );
}

void main() {
  group('currentMonthCategoryBreakdownProvider', () {
    test('buckets expense + income by category with correct percentages', () async {
      final now = DateTime.now();
      String at(int day, [int hour = 4]) {
        final m = now.month.toString().padLeft(2, '0');
        final d = day.toString().padLeft(2, '0');
        final h = hour.toString().padLeft(2, '0');
        return '${now.year}-$m-${d}T$h:00:00Z';
      }

      final repo = _FakeTransactionRepository([
        // Expense: food 300k (200k + 100k), transport 100k, uncategorized 100k.
        _tx(
          id: 'e1',
          type: TransactionType.expense,
          amountMinor: 200000,
          transactionAt: at(1),
          categoryId: 'c-food',
        ),
        _tx(
          id: 'e2',
          type: TransactionType.expense,
          amountMinor: 100000,
          transactionAt: at(2),
          categoryId: 'c-food',
        ),
        _tx(
          id: 'e3',
          type: TransactionType.expense,
          amountMinor: 100000,
          transactionAt: at(2),
          categoryId: 'c-transport',
        ),
        _tx(
          id: 'e4',
          type: TransactionType.expense,
          amountMinor: 100000,
          transactionAt: at(3),
          categoryId: null,
        ),
        // Income: salary 8jt.
        _tx(
          id: 'i1',
          type: TransactionType.income,
          amountMinor: 8000000,
          transactionAt: at(1),
          categoryId: 'c-salary',
        ),
        // Transfer must be ignored entirely.
        _tx(
          id: 't1',
          type: TransactionType.transfer,
          amountMinor: 500000,
          transactionAt: at(2),
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
          categoryTagManagementControllerProvider.overrideWith(
            _StubCategoriesController.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(
        currentMonthCategoryBreakdownProvider.future,
      );

      // Totals ignore the transfer.
      expect(data.expenseTotalMinor, 500000);
      expect(data.incomeTotalMinor, 8000000);

      // Expense: sorted desc, food (300k) first, then transport / uncategorized
      // (both 100k), each joined to its category.
      final expense = data.expenseByCategory;
      expect(expense.length, 3);
      expect(expense.first.categoryId, 'c-food');
      expect(expense.first.name, 'Makanan');
      expect(expense.first.icon, Icons.restaurant_outlined);
      expect(expense.first.color, const Color(0xFF2E8B57));
      expect(expense.first.amountMinor, 300000);
      expect(expense.first.percentOfTotal, closeTo(60, 0.001));

      // The uncategorized bucket collapses null-category expenses.
      final uncategorized = expense.firstWhere((s) => s.categoryId == null);
      expect(uncategorized.name, kUncategorizedName);
      expect(uncategorized.color, isNull);
      expect(uncategorized.amountMinor, 100000);
      expect(uncategorized.percentOfTotal, closeTo(20, 0.001));

      // Income: one salary slice at 100%.
      final income = data.incomeByCategory;
      expect(income.length, 1);
      expect(income.single.categoryId, 'c-salary');
      expect(income.single.name, 'Gaji');
      expect(income.single.amountMinor, 8000000);
      expect(income.single.percentOfTotal, closeTo(100, 0.001));
    });

    test('drops transactions outside the current month', () async {
      final now = DateTime.now();
      // A day well inside the current month.
      final inMonth =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-15T04:00:00Z';
      // A day in the previous month (still inside the widened API window).
      final prev = DateTime(
        now.year,
        now.month,
        1,
      ).subtract(const Duration(days: 1));
      final outMonth =
          '${prev.year}-${prev.month.toString().padLeft(2, '0')}-'
          '${prev.day.toString().padLeft(2, '0')}T04:00:00Z';

      final repo = _FakeTransactionRepository([
        _tx(
          id: 'in',
          type: TransactionType.expense,
          amountMinor: 100000,
          transactionAt: inMonth,
          categoryId: 'c-food',
        ),
        _tx(
          id: 'out',
          type: TransactionType.expense,
          amountMinor: 999000,
          transactionAt: outMonth,
          categoryId: 'c-food',
        ),
      ]);

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repo),
          categoryTagManagementControllerProvider.overrideWith(
            _StubCategoriesController.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final data = await container.read(
        currentMonthCategoryBreakdownProvider.future,
      );

      // Only the in-month expense counts.
      expect(AffluenaDateFormatter.localDay(outMonth).month, isNot(now.month));
      expect(data.expenseTotalMinor, 100000);
      expect(data.expenseByCategory.single.amountMinor, 100000);
    });
  });
}
