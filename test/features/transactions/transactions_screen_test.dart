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

    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();

    expect(repository.requestedTypes, contains(TransactionType.expense));

    await tester.scrollUntilVisible(
      find.text('Load more'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Load more'));
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

    expect(find.text('Transaction detail'), findsOneWidget);
    expect(find.text('GoPay'), findsWidgets);
    expect(find.text('Food & Dining'), findsWidgets);

    await tester.tap(find.text('Delete transaction'));
    await tester.pumpAndSettle();

    // Delete now routes through a coral confirmation dialog before mutating.
    expect(find.text('Delete this transaction?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('transaction-delete-confirm')));
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
    await tester.tap(find.text('Delete transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-delete-confirm')));
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
    expect(find.text('Load more'), findsNothing);
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
    await tester.tap(find.text('Delete transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-delete-confirm')));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [groceriesTransaction.id]);
    expect(find.text('Groceries at Indomaret'), findsOneWidget);
    // Failure surfaces as a coral error banner on the list.
    expect(find.text('Transaction could not be deleted.'), findsWidgets);
  });
}
