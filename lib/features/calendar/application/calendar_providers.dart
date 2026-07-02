import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../transactions/data/transaction_models.dart';
import '../../transactions/data/transaction_repository.dart';

/// One local calendar day's money activity.
class CalendarDaySummary {
  const CalendarDaySummary({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.transactions,
  });

  final int incomeMinor;
  final int expenseMinor;

  /// Every transaction of the day (incl. transfers/adjustments), oldest first.
  final List<Transaction> transactions;

  int get netMinor => incomeMinor - expenseMinor;
}

/// A whole month, aggregated per local day.
class CalendarMonthData {
  const CalendarMonthData({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.days,
  });

  final int incomeMinor;
  final int expenseMinor;

  /// Keyed by day-of-month (1-based); days without activity are absent.
  final Map<int, CalendarDaySummary> days;

  int get netMinor => incomeMinor - expenseMinor;
}

/// Fetches and aggregates one month of transactions, keyed by `yyyy-MM`.
///
/// The API window is widened by a day on each edge (the `from`/`to` params
/// are date-typed while bucketing is by LOCAL day), then transactions are
/// bucketed via [AffluenaDateFormatter.localDay] and non-month days dropped —
/// correct regardless of the backend's boundary semantics or timezone skew.
/// Only income/expense count toward the totals; transfers and adjustments
/// still appear in the day's transaction list.
final calendarMonthProvider = FutureProvider.autoDispose
    .family<CalendarMonthData, String>((ref, monthKey) async {
      final repo = ref.watch(transactionRepositoryProvider);
      final parts = monthKey.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      String isoDate(DateTime d) {
        final m = d.month.toString().padLeft(2, '0');
        final day = d.day.toString().padLeft(2, '0');
        return '${d.year}-$m-${day}T00:00:00Z';
      }

      final from = DateTime(year, month, 1).subtract(const Duration(days: 1));
      final to = DateTime(year, month + 1, 2);

      const pageSize = 200;
      const maxTransactions = 5000;
      final all = <Transaction>[];
      var offset = 0;
      while (true) {
        final page = await repo.listTransactions(
          from: isoDate(from),
          to: isoDate(to),
          limit: pageSize,
          offset: offset,
          sort: 'transaction_at_desc',
        );
        all.addAll(page.transactions);
        offset += page.transactions.length;
        if (page.transactions.isEmpty ||
            offset >= page.pagination.total ||
            offset >= maxTransactions) {
          break;
        }
      }

      final byDay = <int, List<Transaction>>{};
      for (final tx in all) {
        final day = AffluenaDateFormatter.localDay(tx.transactionAt);
        if (day.year != year || day.month != month) continue;
        byDay.putIfAbsent(day.day, () => []).add(tx);
      }

      var monthIncome = 0;
      var monthExpense = 0;
      final days = <int, CalendarDaySummary>{};
      byDay.forEach((day, txs) {
        txs.sort((a, b) => a.transactionAt.compareTo(b.transactionAt));
        var income = 0;
        var expense = 0;
        for (final tx in txs) {
          switch (tx.type) {
            case TransactionType.income:
              income += tx.amountMinor;
            case TransactionType.expense:
              expense += tx.amountMinor;
            case TransactionType.transfer:
            case TransactionType.adjustment:
              break;
          }
        }
        monthIncome += income;
        monthExpense += expense;
        days[day] = CalendarDaySummary(
          incomeMinor: income,
          expenseMinor: expense,
          transactions: txs,
        );
      });

      return CalendarMonthData(
        incomeMinor: monthIncome,
        expenseMinor: monthExpense,
        days: days,
      );
    });
