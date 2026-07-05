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
      await tester.tap(find.text('Ubah transaksi'));
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

      // Tapping it opens the tree picker (search is now behind a header icon;
      // the manage gear is always present, so use it to detect the sheet).
      await tester.tap(selector);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('category-picker-manage-button')),
        findsOneWidget,
      );

      // Pick the nested child; the picker pops and the selector updates.
      await tester.tap(find.text('Groceries'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('category-picker-manage-button')),
        findsNothing,
      );
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
    await tester.tap(find.text('Ubah transaksi'));
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
    await tester.tap(find.text('Ubah transaksi'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transaction-edit-amount-field')),
      '0',
    );
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedRequests, isEmpty);
    expect(find.text('Jumlah harus lebih dari 0.'), findsOneWidget);
    expect(find.text('Ubah transaksi'), findsOneWidget);
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
    await tester.tap(find.text('Ubah transaksi'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('transaction-edit-note-field')),
      'Retry after reconnect',
    );
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedIds, [groceriesTransaction.id]);
    expect(find.text('Transaksi tidak dapat diperbarui.'), findsWidgets);
    expect(find.text('Ubah transaksi'), findsOneWidget);
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
      await tester.tap(find.text('Ubah transaksi'));
      await tester.pumpAndSettle();

      // The positive-only MoneyInput shows the magnitude, not the signed
      // value. Assert the editable value specifically — the field's hintText
      // ('50.000') stays in the InputDecorator tree even when filled.
      final amountEditable = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('transaction-edit-amount-field')),
          matching: find.byType(EditableText),
        ),
      );
      expect(amountEditable.controller.text, '50.000');

      // Decrease is preselected for a negative adjustment.
      final decreaseChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Kurangi (−)'),
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
    await tester.tap(find.text('Ubah transaksi'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah (+)'));
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
    await tester.tap(find.text('Ubah transaksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('BCA Primary').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-edit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedRequests, isEmpty);
    expect(find.text('Dompet tujuan wajib diisi.'), findsOneWidget);
    expect(find.text('Ubah transaksi'), findsOneWidget);
  });
}
