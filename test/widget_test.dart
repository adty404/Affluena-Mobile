import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:affluena_mobile/app/theme/affluena_theme.dart';

import 'helpers/auth_test_helpers.dart';

void main() {
  testWidgets('renders Affluena dashboard shell', (tester) async {
    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    expect(find.text('Affluena'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Total balance'), findsOneWidget);
  });

  testWidgets('navigates to quick entry from bottom nav', (tester) async {
    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Quick entry'), findsOneWidget);
    expect(find.text('Rp 125.000'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save transaction'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Save transaction'), findsOneWidget);
  });

  testWidgets('core shell follows platform dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    final dashboardContext = tester.element(find.text('Good morning'));
    expect(Theme.of(dashboardContext).brightness, Brightness.dark);
    expect(
      dashboardContext.affluenaColors.surfaceCanvas,
      AffluenaColors.darkCanvas,
    );

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Wallets'), findsWidgets);
    expect(
      tester.element(find.text('Wallets').first).affluenaColors.surfaceSoft,
      AffluenaColors.darkSurface,
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    expect(find.text('Quick entry'), findsOneWidget);
    expect(
      tester.element(find.text('Quick entry')).affluenaColors.forestSoft,
      AffluenaColors.darkForestSoft,
    );

    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Transactions'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
  });
}
