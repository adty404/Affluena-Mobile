import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'wallets_test_helpers.dart';

void main() {
  setUpAll(() async {
    // The adjustment sheet's DateTimePickerField formats with the 'id_ID'
    // locale, mirroring main(); initialize it before the widgets build.
    await initializeDateFormatting('id_ID');
  });

  testWidgets('creates wallet and refreshes repository list', (tester) async {
    final repository = TestWalletRepository(wallets: [cashWallet]);

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Travel Cash',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Starting balance'),
      '250000',
    );
    await tester.tap(find.text('Save wallet'));
    await tester.pumpAndSettle();

    expect(repository.createRequests, hasLength(1));
    expect(repository.createRequests.single.name, 'Travel Cash');
    expect(repository.createRequests.single.balanceMinor, 250000);
    expect(find.text('Travel Cash'), findsOneWidget);
  });

  testWidgets('create wallet error keeps form open with feedback', (
    tester,
  ) async {
    final repository = TestWalletRepository(
      wallets: [cashWallet],
      createError: Exception('network'),
    );

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Travel Cash',
    );
    await tester.tap(find.text('Save wallet'));
    await tester.pumpAndSettle();

    expect(repository.createRequests, hasLength(1));
    expect(find.text('New wallet'), findsOneWidget);
    expect(find.text('Wallet could not be saved.'), findsOneWidget);
  });

  testWidgets('create wallet validates required name before request', (
    tester,
  ) async {
    final repository = TestWalletRepository(wallets: [cashWallet]);

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save wallet'));
    await tester.pumpAndSettle();

    expect(repository.createRequests, isEmpty);
    expect(find.text('Wallet name is required.'), findsOneWidget);
    expect(find.text('New wallet'), findsOneWidget);
  });

  testWidgets('create wallet can be cancelled without a repository request', (
    tester,
  ) async {
    final repository = TestWalletRepository(wallets: [cashWallet]);

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Travel Cash',
    );
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(repository.createRequests, isEmpty);
    expect(find.text('New wallet'), findsNothing);
    expect(find.text('Travel Cash'), findsNothing);
  });

  testWidgets('edits wallet and refreshes repository list', (tester) async {
    final repository = TestWalletRepository(wallets: [cashWallet]);

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-wallet-cash-wallet')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Daily Cash',
    );
    await tester.tap(find.text('Save wallet'));
    await tester.pumpAndSettle();

    expect(repository.updateIds, [cashWallet.id]);
    expect(repository.updateRequests.single.name, 'Daily Cash');
    expect(repository.updateRequests.single.balanceMinor, isNull);
    expect(find.text('Daily Cash'), findsOneWidget);
    expect(find.text('Cash Wallet'), findsNothing);
  });

  testWidgets('edit wallet exposes an adjust-balance entry that opens the '
      'adjustment sheet', (tester) async {
    final repository = TestWalletRepository(wallets: [cashWallet]);

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-wallet-cash-wallet')));
    await tester.pumpAndSettle();

    // Balance is not editable inline on the edit form; it is changed through an
    // adjustment (penyesuaian) transaction reached from this entry.
    expect(find.text('Edit wallet'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Starting balance'), findsNothing);
    final adjustEntry = find.byKey(const Key('wallet-edit-adjust-balance'));
    expect(adjustEntry, findsOneWidget);

    await tester.tap(adjustEntry);
    await tester.pumpAndSettle();

    // The adjustment sheet (records an adjustment transaction) is now open.
    expect(find.text('Adjust balance'), findsOneWidget);
    expect(find.byKey(const Key('wallet-adjust-amount-field')), findsOneWidget);
    expect(find.byKey(const Key('wallet-adjust-save-button')), findsOneWidget);
  });

  testWidgets('edit wallet error keeps form open with feedback', (
    tester,
  ) async {
    final repository = TestWalletRepository(
      wallets: [cashWallet],
      updateError: Exception('network'),
    );

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-wallet-cash-wallet')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Daily Cash',
    );
    await tester.tap(find.text('Save wallet'));
    await tester.pumpAndSettle();

    expect(repository.updateIds, [cashWallet.id]);
    expect(find.text('Edit wallet'), findsOneWidget);
    expect(find.text('Wallet could not be saved.'), findsOneWidget);
  });

  testWidgets('edit wallet can be cancelled without a repository request', (
    tester,
  ) async {
    final repository = TestWalletRepository(wallets: [cashWallet]);

    await tester.pumpWidget(walletsTestApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-wallet-cash-wallet')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Daily Cash',
    );
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(repository.updateRequests, isEmpty);
    expect(find.text('Edit wallet'), findsNothing);
    expect(find.text('Cash Wallet'), findsOneWidget);
    expect(find.text('Daily Cash'), findsNothing);
  });
}
