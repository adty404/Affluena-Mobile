import 'package:affluena_mobile/app/provider_retry.dart';
import 'package:affluena_mobile/features/categories/data/category_repository.dart';
import 'package:affluena_mobile/features/tags/data/tag_repository.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_models.dart';
import 'package:affluena_mobile/features/transactions/data/transaction_repository.dart';
import 'package:affluena_mobile/features/transactions/presentation/transaction_create_screen.dart';
import 'package:affluena_mobile/features/wallets/data/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'transactions_test_helpers.dart';

/// A minimal two-route GoRouter so `TransactionCreateScreen`'s `context.pop()`
/// (fired on a successful create) has a back-stack to pop to. The home route
/// carries a "buka" button that pushes the create screen.
Widget _createTestApp(RecordingTransactionRepository repository) {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, _) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => context.push(TransactionCreateScreen.path),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: TransactionCreateScreen.path,
        builder: (_, _) => const TransactionCreateScreen(),
      ),
    ],
  );
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repository),
      walletRepositoryProvider.overrideWithValue(
        const StaticWalletRepository(wallets: [gopayWallet, bcaWallet]),
      ),
      categoryRepositoryProvider.overrideWithValue(
        const StaticCategoryRepository(
          categories: [foodCategory, salaryCategory],
        ),
      ),
      tagRepositoryProvider.overrideWithValue(
        const StaticTransactionsTagRepository(tags: []),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _openCreateScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    _createTestApp(
      _repository = RecordingTransactionRepository(transactions: const []),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('buka'));
  await tester.pumpAndSettle();
}

late RecordingTransactionRepository _repository;

void main() {
  testWidgets('fills the form and creates an expense with the chosen wallet + '
      'category, then pops', (tester) async {
    await _openCreateScreen(tester);
    final repository = _repository;

    // Amount (minor units typed directly through MoneyInput).
    await tester.enterText(
      find.byKey(const Key('transaction-create-amount-field')),
      '50000',
    );
    await tester.pumpAndSettle();

    // Wallet: tap the selector, pick GoPay from the lookup sheet.
    await tester.tap(
      find.byKey(const Key('transaction-create-wallet-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('GoPay').last);
    await tester.pumpAndSettle();

    // Category: tap the selector, pick the expense category from the picker.
    await tester.tap(
      find.byKey(const Key('transaction-create-category-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining').last);
    await tester.pumpAndSettle();

    // Submit.
    final submit = find.byKey(const Key('transaction-create-submit-button'));
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // The create request carried the chosen wallet/category/amount + expense.
    final request = repository.createdRequests.single;
    expect(request.type, TransactionType.expense);
    expect(request.walletId, gopayWallet.id);
    expect(request.categoryId, foodCategory.id);
    expect(request.amountMinor, 50000);
    // On success the screen pops back to /home.
    expect(find.text('buka'), findsOneWidget);
  });

  testWidgets('a quick-amount chip SETS the amount and submit carries it', (
    tester,
  ) async {
    await _openCreateScreen(tester);
    final repository = _repository;

    // Type one value first, then tap a chip — the chip must REPLACE it.
    await tester.enterText(
      find.byKey(const Key('transaction-create-amount-field')),
      '12345',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('amount-chip-50000')));
    await tester.pumpAndSettle();

    // The MoneyInput now shows the grouped preset, not the typed value.
    // (find.text matches both the EditableText and its inner render — use
    // findsWidgets and assert the typed value is fully gone.)
    expect(find.text('50.000'), findsWidgets);
    expect(find.text('12.345'), findsNothing);

    await tester.tap(
      find.byKey(const Key('transaction-create-wallet-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('GoPay').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('transaction-create-category-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food & Dining').last);
    await tester.pumpAndSettle();

    final submit = find.byKey(const Key('transaction-create-submit-button'));
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // The request carries the chip's value — replaced, never added.
    expect(repository.createdRequests.single.amountMinor, 50000);
  });

  testWidgets('blocks submit and creates nothing when required fields are '
      'missing', (tester) async {
    await _openCreateScreen(tester);
    final repository = _repository;

    // Submit immediately — no wallet, no amount, no category.
    final submit = find.byKey(const Key('transaction-create-submit-button'));
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(submit);
    await tester.pumpAndSettle();

    // Nothing was created and we're still on the create screen (not popped).
    expect(repository.createdRequests, isEmpty);
    expect(submit, findsOneWidget);
    expect(find.text('buka'), findsNothing);
  });
}
