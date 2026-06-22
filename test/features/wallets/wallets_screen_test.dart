import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallets_test_helpers.dart';

void main() {
  testWidgets('renders repository wallets and marks goal wallets read-only', (
    tester,
  ) async {
    await tester.pumpWidget(
      walletsTestApp(
        TestWalletRepository(
          wallets: [cashWallet, bankWallet, goPayWallet, goalWallet],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cash Wallet'), findsOneWidget);
    expect(find.text('BCA Primary'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('GoPay'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('GoPay'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Europe Trip Fund'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Europe Trip Fund'), findsOneWidget);
    expect(find.textContaining('Read-only goal wallet'), findsOneWidget);
    expect(find.byKey(const Key('edit-wallet-goal-wallet')), findsNothing);
  });

  testWidgets('empty wallet list shows helpful state', (tester) async {
    await tester.pumpWidget(walletsTestApp(TestWalletRepository(wallets: [])));
    await tester.pumpAndSettle();

    expect(find.text('No wallets yet'), findsOneWidget);
    expect(
      find.text('Create a wallet before recording transactions.'),
      findsOneWidget,
    );
  });
}
