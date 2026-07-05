import 'package:affluena_mobile/core/formatters/date_formatter.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transactions_test_helpers.dart';

void main() {
  testWidgets('renders transaction list with wallet and category names', (
    tester,
  ) async {
    await tester.pumpWidget(
      transactionsTestApp(
        transactionRepository: RecordingTransactionRepository(
          transactions: [groceriesTransaction, salaryTransaction],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Groceries at Indomaret'), findsOneWidget);
    // Day-grouped list: the date is the section header, the row shows category ·
    // wallet · time. Assert the time-agnostic prefix so the test is tz-stable.
    expect(find.textContaining('Food & Dining · GoPay'), findsOneWidget);
    expect(find.text('Monthly Salary'), findsOneWidget);
    expect(find.textContaining('Salary · BCA Primary'), findsOneWidget);
    expect(find.text(gopayWallet.id), findsNothing);
    expect(find.text(foodCategory.id), findsNothing);
  });

  testWidgets('maps expense filter and load more to API query params', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [
        groceriesTransaction,
        fuelTransaction,
        coffeeTransaction,
        lunchTransaction,
        electricityTransaction,
        entertainmentTransaction,
      ],
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengeluaran'));
    await tester.pumpAndSettle();

    expect(repository.requestedTypes, contains(TransactionType.expense));

    await tester.scrollUntilVisible(
      find.text('Muat lebih banyak'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // The drill-in AppBar shortens the body, so nudge the button fully into
    // view before tapping (it can otherwise settle just below the fold).
    await tester.ensureVisible(find.text('Muat lebih banyak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Muat lebih banyak'));
    await tester.pumpAndSettle();

    expect(repository.requestedOffsets, contains(5));
  });

  testWidgets('opens mapped detail sheet and deletes after API success', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [groceriesTransaction],
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries at Indomaret'));
    await tester.pumpAndSettle();

    expect(find.text('Detail transaksi'), findsOneWidget);
    expect(find.text('GoPay'), findsWidgets);
    expect(find.text('Food & Dining'), findsWidgets);
    // The detail shows the full date AND time-of-day, not just the date.
    expect(find.text('Tanggal & waktu'), findsOneWidget);
    expect(
      find.text(
        AffluenaDateFormatter.dateTime(groceriesTransaction.transactionAt),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Hapus transaksi'));
    await tester.pumpAndSettle();

    // Delete routes through the shared coral skyConfirm sheet before mutating.
    expect(find.text('Hapus transaksi ini?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sky-confirm-accept')));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [groceriesTransaction.id]);
    expect(find.text('Groceries at Indomaret'), findsNothing);
  });

  testWidgets('delete success refreshes the first page from backend state', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [
        groceriesTransaction,
        fuelTransaction,
        coffeeTransaction,
        lunchTransaction,
        electricityTransaction,
        entertainmentTransaction,
      ],
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Movie Night'), findsNothing);

    await tester.tap(find.text('Groceries at Indomaret'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus transaksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky-confirm-accept')));
    await tester.pumpAndSettle();

    expect(find.text('Groceries at Indomaret'), findsNothing);
    // The day-grouped list is taller than the viewport; scroll the remaining
    // item (from the refreshed backend state) into view before asserting.
    await tester.scrollUntilVisible(
      find.text('Movie Night'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Movie Night'), findsOneWidget);
    expect(find.text('Muat lebih banyak'), findsNothing);
  });

  testWidgets('delete failure preserves row and shows error', (tester) async {
    final repository = RecordingTransactionRepository(
      transactions: [groceriesTransaction],
      deleteError: Exception('forbidden'),
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries at Indomaret'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus transaksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sky-confirm-accept')));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [groceriesTransaction.id]);
    expect(find.text('Groceries at Indomaret'), findsOneWidget);
    // Failure surfaces as a coral error banner on the list.
    expect(find.text('Transaksi tidak dapat dihapus.'), findsWidgets);
  });
}
