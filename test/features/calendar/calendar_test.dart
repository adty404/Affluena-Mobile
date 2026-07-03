import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/core/formatters/date_formatter.dart';
import 'package:affluena_mobile/core/formatters/money_formatter.dart';
import 'package:affluena_mobile/features/calendar/application/calendar_providers.dart';
import 'package:affluena_mobile/features/calendar/presentation/calendar_screen.dart';
import 'package:affluena_mobile/features/categories/application/category_tag_management_controller.dart';
import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:affluena_mobile/features/shared/presentation/appearance/item_appearance.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/transactions/presentation/transaction_display.dart';
import 'package:affluena_mobile/features/wallets/application/wallets_controller.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _wallet = Wallet(
  id: 'w1',
  userId: 'u1',
  name: 'GoPay',
  type: WalletType.eWallet,
  currencyCode: 'IDR',
  balanceMinor: 0,
  color: '',
  description: '',
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

// A category with a chosen icon + color so the day sheet must render that
// glyph in that color on the transaction tile.
const _foodColor = '#2E8B57';
const _food = Category(
  id: 'c-food',
  userId: 'u1',
  name: 'Makanan',
  type: CategoryType.expense,
  icon: 'food',
  color: _foodColor,
  createdAt: '2026-06-01T00:00:00Z',
  updatedAt: '2026-06-01T00:00:00Z',
);

// Stub the category catalog (no microtask load) so the day sheet resolves the
// category hermetically.
class _StubCategoriesController extends CategoryTagManagementController {
  @override
  CategoryTagManagementState build() =>
      const CategoryTagManagementState(categories: [_food]);
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
    return TransactionListResponse(
      transactions: transactions,
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
  String note = '',
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
    note: note,
    createdAt: transactionAt,
    updatedAt: transactionAt,
  );
}

void main() {
  group('MoneyFormatter.compactIdr', () {
    test('formats thresholds with Indonesian suffixes', () {
      expect(MoneyFormatter.compactIdr(0), '0');
      expect(MoneyFormatter.compactIdr(950), '950');
      expect(MoneyFormatter.compactIdr(25000), '25rb');
      expect(MoneyFormatter.compactIdr(999500), '999,5rb');
      expect(MoneyFormatter.compactIdr(1200000), '1,2jt');
      expect(MoneyFormatter.compactIdr(950000000), '950jt');
      expect(MoneyFormatter.compactIdr(2500000000), '2,5M');
      expect(MoneyFormatter.compactIdr(-25000), '25rb');
    });
  });

  group('calendarMonthProvider', () {
    test('aggregates income/expense per local day and for the month', () async {
      final now = DateTime.now();
      final monthKey = AffluenaDateFormatter.monthKey(now);
      String at(int day, [int hour = 4]) {
        final m = now.month.toString().padLeft(2, '0');
        final d = day.toString().padLeft(2, '0');
        final h = hour.toString().padLeft(2, '0');
        return '${now.year}-$m-${d}T$h:00:00Z';
      }

      final repo = _FakeTransactionRepository([
        _tx(
          id: 't1',
          type: TransactionType.income,
          amountMinor: 8000000,
          transactionAt: at(1),
        ),
        _tx(
          id: 't2',
          type: TransactionType.expense,
          amountMinor: 250000,
          transactionAt: at(1),
        ),
        _tx(
          id: 't3',
          type: TransactionType.expense,
          amountMinor: 100000,
          transactionAt: at(2),
        ),
        // Transfers must not count toward totals but still appear in the day.
        _tx(
          id: 't4',
          type: TransactionType.transfer,
          amountMinor: 500000,
          transactionAt: at(2),
        ),
      ]);
      final container = ProviderContainer(
        overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final data = await container.read(calendarMonthProvider(monthKey).future);

      expect(data.incomeMinor, 8000000);
      expect(data.expenseMinor, 350000);
      expect(data.netMinor, 7650000);
      final day1 = AffluenaDateFormatter.localDay(at(1)).day;
      final day2 = AffluenaDateFormatter.localDay(at(2)).day;
      expect(data.days[day1]?.incomeMinor, 8000000);
      expect(data.days[day1]?.expenseMinor, 250000);
      expect(data.days[day2]?.expenseMinor, 100000);
      expect(data.days[day2]?.incomeMinor, 0);
      expect(data.days[day2]?.transactions.length, 2);
    });
  });

  group('CalendarView', () {
    testWidgets('shows month header, summary, and day amounts', (tester) async {
      final now = DateTime.now();
      String at(int day) {
        final m = now.month.toString().padLeft(2, '0');
        final d = day.toString().padLeft(2, '0');
        return '${now.year}-$m-${d}T04:00:00Z';
      }

      final repo = _FakeTransactionRepository([
        _tx(
          id: 't1',
          type: TransactionType.income,
          amountMinor: 8000000,
          transactionAt: at(1),
        ),
        _tx(
          id: 't2',
          type: TransactionType.expense,
          amountMinor: 250000,
          transactionAt: at(1),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: Scaffold(body: CalendarView())),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          AffluenaDateFormatter.monthLabelFull(DateTime(now.year, now.month)),
        ),
        findsOneWidget,
      );
      expect(find.text('Pemasukan'), findsOneWidget);
      expect(find.text('Pengeluaran'), findsOneWidget);
      expect(find.text('Selisih'), findsOneWidget);
      expect(find.text('Sen'), findsOneWidget);
      expect(find.text('+8jt'), findsOneWidget);
      expect(find.text('−250rb'), findsOneWidget);

      // Tapping the active day opens the day sheet with its transactions.
      await tester.tap(find.text('+8jt'));
      await tester.pumpAndSettle();
      expect(find.text('Pemasukan'), findsWidgets);
    });

    testWidgets('day sheet renders the category icon in its chosen color', (
      tester,
    ) async {
      final now = DateTime.now();
      String at(int day) {
        final m = now.month.toString().padLeft(2, '0');
        final d = day.toString().padLeft(2, '0');
        return '${now.year}-$m-${d}T04:00:00Z';
      }

      final repo = _FakeTransactionRepository([
        _tx(
          id: 't1',
          type: TransactionType.expense,
          amountMinor: 250000,
          transactionAt: at(1),
          categoryId: 'c-food',
          note: 'Makan siang',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(repo),
            walletListProvider.overrideWith((ref) async => const [_wallet]),
            categoryTagManagementControllerProvider.overrideWith(
              _StubCategoriesController.new,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CalendarView())),
        ),
      );
      await tester.pumpAndSettle();

      // Open the day sheet for the day with the categorized expense (the
      // expense and net cells both read −250rb; tapping either opens it).
      await tester.tap(find.text('−250rb').first);
      await tester.pumpAndSettle();

      // The tile shows the category's chosen glyph in its chosen color.
      expect(find.text('Makan siang'), findsOneWidget);
      final appearance = categoryAppearanceFor(
        _food,
        type: TransactionType.expense,
      );
      expect(appearance.icon, Icons.restaurant_outlined);
      final icon = tester.widget<Icon>(find.byIcon(Icons.restaurant_outlined));
      expect(icon.color, parseItemColor(_foodColor));
    });

    testWidgets('day sheet exposes an add button and a tappable txn row', (
      tester,
    ) async {
      final now = DateTime.now();
      String at(int day) {
        final m = now.month.toString().padLeft(2, '0');
        final d = day.toString().padLeft(2, '0');
        return '${now.year}-$m-${d}T04:00:00Z';
      }

      final repo = _FakeTransactionRepository([
        _tx(
          id: 't1',
          type: TransactionType.expense,
          amountMinor: 250000,
          transactionAt: at(1),
          categoryId: 'c-food',
          note: 'Makan siang',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(repo),
            walletListProvider.overrideWith((ref) async => const [_wallet]),
            categoryTagManagementControllerProvider.overrideWith(
              _StubCategoriesController.new,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CalendarView())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('−250rb').first);
      await tester.pumpAndSettle();

      // "Tambah" opens quick-add pre-set to this date; the row is tappable to
      // open the transaction detail (edit/delete).
      expect(find.byKey(const Key('calendar-day-add')), findsOneWidget);
      expect(find.byKey(const Key('calendar-day-txn-t1')), findsOneWidget);
    });

    testWidgets(
      'summary header stacks on narrow widths so values are never cut off',
      (tester) async {
        final now = DateTime.now();
        String at(int day) {
          final m = now.month.toString().padLeft(2, '0');
          final d = day.toString().padLeft(2, '0');
          return '${now.year}-$m-${d}T04:00:00Z';
        }

        final repo = _FakeTransactionRepository([
          _tx(
            id: 't1',
            type: TransactionType.income,
            amountMinor: 999999999,
            transactionAt: at(1),
          ),
          _tx(
            id: 't2',
            type: TransactionType.expense,
            amountMinor: 888888888,
            transactionAt: at(1),
          ),
        ]);

        Widget app(double width) => ProviderScope(
          overrides: [transactionRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(width: width, child: const CalendarView()),
              ),
            ),
          ),
        );

        // Narrow: three full IDR values cannot fit side by side — the card
        // stacks (no vertical dividers) and shows the FULL amounts.
        await tester.pumpWidget(app(320));
        await tester.pumpAndSettle();
        expect(find.byType(VerticalDivider), findsNothing);
        expect(find.text('Rp 999.999.999'), findsOneWidget);
        expect(find.text('Rp 888.888.888'), findsOneWidget);

        // Wide: the three-column layout returns (two divider gutters).
        await tester.pumpWidget(app(700));
        await tester.pumpAndSettle();
        expect(find.byType(VerticalDivider), findsNWidgets(2));
      },
    );
  });
}
