import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transactions_test_helpers.dart';

void main() {
  testWidgets('edits an existing transaction and refreshes the list', (
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
    await tester.tap(find.text('Edit transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transaction-edit-amount-field')),
      '125000',
    );
    await tester.enterText(
      find.byKey(const Key('transaction-edit-note-field')),
      'Groceries corrected',
    );
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedIds, [groceriesTransaction.id]);
    expect(repository.updatedRequests.single.amountMinor, 125000);
    expect(repository.updatedRequests.single.note, 'Groceries corrected');
    expect(repository.updatedRequests.single.walletId, gopayWallet.id);
    expect(repository.updatedRequests.single.categoryId, foodCategory.id);
    expect(find.text('Groceries corrected'), findsOneWidget);
    expect(find.text('Groceries at Indomaret'), findsNothing);
    expect(find.text(gopayWallet.id), findsNothing);
    expect(find.text(foodCategory.id), findsNothing);
  });

  testWidgets('edit transaction validates amount before update request', (
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
    await tester.tap(find.text('Edit transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transaction-edit-amount-field')),
      '0',
    );
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedRequests, isEmpty);
    expect(find.text('Amount must be greater than 0.'), findsOneWidget);
    expect(find.text('Edit transaction'), findsOneWidget);
  });

  testWidgets('edit transaction failure stays open and can retry', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [groceriesTransaction],
      updateError: Exception('offline'),
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries at Indomaret'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transaction-edit-note-field')),
      'Retry after reconnect',
    );
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedIds, [groceriesTransaction.id]);
    expect(find.text('Transaction could not be updated.'), findsWidgets);
    expect(find.text('Edit transaction'), findsOneWidget);
    expect(
      find.byKey(const Key('transaction-edit-save-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedIds, [
      groceriesTransaction.id,
      groceriesTransaction.id,
    ]);
  });

  testWidgets('transfer edit clears destination when source changes to it', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [transferTransaction],
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Move to savings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit transaction'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('BCA Primary').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedRequests, isEmpty);
    expect(find.text('Destination wallet is required.'), findsOneWidget);
    expect(find.text('Edit transaction'), findsOneWidget);
  });
}
