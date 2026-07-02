import 'package:affluena_mobile/core/api/pagination.dart';
import 'package:affluena_mobile/core/formatters/date_formatter.dart';
import 'package:affluena_mobile/core/formatters/money_formatter.dart';
import 'package:affluena_mobile/features/calendar/application/calendar_providers.dart';
import 'package:affluena_mobile/features/calendar/presentation/calendar_screen.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}) {
  return Transaction(
    id: id,
    userId: 'u1',
    type: type,
    walletId: 'w1',
    amountMinor: amountMinor,
    tagIds: const [],
    transactionAt: transactionAt,
    note: '',
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
  });
}
