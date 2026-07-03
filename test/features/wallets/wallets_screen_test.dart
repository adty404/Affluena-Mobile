import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'wallets_test_helpers.dart';

/// Finds a card painted solid in [color] (the AffluenaCard DecoratedBox whose
/// BoxDecoration carries the item's chosen color as its fill).
Finder _solidCard(Color color) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == color,
  );
}

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

  testWidgets('wallet with a chosen color renders a solid colored card', (
    tester,
  ) async {
    await tester.pumpWidget(
      walletsTestApp(TestWalletRepository(wallets: [greenWallet, cashWallet])),
    );
    await tester.pumpAndSettle();

    // The colored wallet paints its whole card solid, with white title and
    // balance — the same treatment as Beranda's dashboard cards.
    const green = Color(0xFF2E8B57);
    expect(_solidCard(green), findsOneWidget);
    final title = tester.widget<Text>(find.text('Dompet Hijau'));
    expect(title.style?.color, Colors.white);
    final balance = tester.widget<Text>(find.text('Rp 1.000.000'));
    expect(balance.style?.color, Colors.white);

    // A wallet without a parseable color keeps the default (non-white) title.
    final plainTitle = tester.widget<Text>(find.text('Cash Wallet'));
    expect(plainTitle.style?.color, isNot(Colors.white));
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
