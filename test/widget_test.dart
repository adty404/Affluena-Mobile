import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/auth_test_helpers.dart';

void main() {
  testWidgets('authenticated start renders the redesign home shell', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    // The Beranda dashboard is the default tab.
    expect(find.text('Total saldo'), findsOneWidget);
    // The Sky bottom nav tabs + center quick-add FAB.
    expect(find.byKey(const Key('nav-beranda')), findsOneWidget);
    expect(find.byKey(const Key('nav-aktivitas')), findsOneWidget);
    expect(find.byKey(const Key('nav-wawasan')), findsOneWidget);
    expect(find.byKey(const Key('nav-lainnya')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('quick-add sheet opens from the home FAB', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // The Sky quick-add capture sheet.
    expect(find.text('Catat cepat'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.byKey(const Key('sky-calc-confirm')), findsOneWidget);
  });

  testWidgets('quick-add sheet lists templates and records one on tap', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // The "PAKAI TEMPLATE" row with the seeded template chip.
    expect(find.text('PAKAI TEMPLATE'), findsOneWidget);
    expect(find.text('Daily Coffee'), findsOneWidget);

    // One tap records it (via the fake repo) and closes the sheet.
    await tester.tap(find.text('Daily Coffee'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5)); // flush the success SnackBar
    await tester.pumpAndSettle();
    expect(find.text('Catat cepat'), findsNothing);
  });

  testWidgets('feature screens follow the platform dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    // The home shell uses a fixed Sky palette, but the feature surfaces reached
    // via "Lainnya" still honour the platform brightness.
    await tester.tap(find.byKey(const Key('nav-lainnya')));
    await tester.pumpAndSettle();

    final settingsContext = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(settingsContext).brightness, Brightness.dark);
    expect(
      settingsContext.affluenaColors.surfaceCanvas,
      AffluenaColors.darkCanvas,
    );
  });
}
