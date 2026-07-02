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
    expect(find.textContaining('Dompet target hanya-baca'), findsOneWidget);
    expect(find.byKey(const Key('edit-wallet-goal-wallet')), findsNothing);
  });

  testWidgets('empty wallet list shows helpful state', (tester) async {
    await tester.pumpWidget(walletsTestApp(TestWalletRepository(wallets: [])));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada dompet'), findsOneWidget);
    expect(
      find.text('Buat dompet dulu sebelum mencatat transaksi.'),
      findsOneWidget,
    );
    // The empty state carries a CTA that opens the create-wallet form.
    await tester.tap(find.widgetWithText(FilledButton, 'Buat dompet'));
    await tester.pumpAndSettle();
    expect(find.text('Dompet baru'), findsOneWidget);
  });
}
