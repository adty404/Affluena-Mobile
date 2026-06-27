import 'package:affluena_mobile/features/categories/data/category_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'transactions_test_helpers.dart';

void main() {
  testWidgets(
    'edit category opens the tree picker and saves the chosen child',
    (tester) async {
      // A child expense category nested under Food & Dining so the
      // hierarchy-aware picker (not a flat dropdown) is exercised.
      const groceriesSubcategory = Category(
        id: '44444444-4444-4444-4444-444444440002',
        userId: transactionsTestUserId,
        name: 'Groceries',
        type: CategoryType.expense,
        // foodCategory.id — inlined because const expressions can't read it.
        parentId: '44444444-4444-4444-4444-444444440001',
        createdAt: '2026-06-01T00:00:00Z',
        updatedAt: '2026-06-01T00:00:00Z',
      );
      final repository = RecordingTransactionRepository(
        transactions: [groceriesTransaction],
      );

      await tester.pumpWidget(
        transactionsTestApp(
          transactionRepository: repository,
          categories: const [
            foodCategory,
            groceriesSubcategory,
            salaryCategory,
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Groceries at Indomaret'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit transaction'));
      await tester.pumpAndSettle();

      // The selector row resolves the current category to its name.
      final selector = find.byKey(
        const Key('transaction-edit-category-selector'),
      );
      expect(selector, findsOneWidget);
      expect(
        find.descendant(of: selector, matching: find.text('Food & Dining')),
        findsOneWidget,
      );

      // Tapping it opens the tree picker (identified by its search field).
      await tester.tap(selector);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('category-tree-search-field')),
        findsOneWidget,
      );

      // Pick the nested child; the picker pops and the selector updates.
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category-tree-search-field')), findsNothing);
      expect(
        find.descendant(of: selector, matching: find.text('Groceries')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
      await tester.pumpAndSettle();

      expect(
        repository.updatedRequests.single.categoryId,
        groceriesSubcategory.id,
      );
    },
  );

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

  testWidgets(
    'negative adjustment preselects Decrease and shows the absolute amount',
    (tester) async {
      final repository = RecordingTransactionRepository(
        transactions: [balanceDecreaseAdjustment],
      );

      await tester.pumpWidget(
        transactionsTestApp(transactionRepository: repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Correct overstated balance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit transaction'));
      await tester.pumpAndSettle();

      // The positive-only MoneyInput shows the magnitude, not the signed value.
      expect(find.text('50.000'), findsOneWidget);

      // Decrease is preselected for a negative adjustment.
      final decreaseChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Decrease (−)'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(decreaseChip.selected, isTrue);

      // Saving without changes preserves the negative sign.
      await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
      await tester.pumpAndSettle();

      expect(repository.updatedRequests.single.amountMinor, -50000);
    },
  );

  testWidgets('toggling an adjustment to Increase sends a positive amount', (
    tester,
  ) async {
    final repository = RecordingTransactionRepository(
      transactions: [balanceDecreaseAdjustment],
    );

    await tester.pumpWidget(
      transactionsTestApp(transactionRepository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Correct overstated balance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit transaction'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Increase (+)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedRequests.single.amountMinor, 50000);
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
