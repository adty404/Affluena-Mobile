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

    // The Spaces home (rooms) is the default tab.
    expect(find.text('TOTAL'), findsOneWidget);
    // The Sky bottom nav tabs + center quick-add FAB.
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Aktivitas'), findsOneWidget);
    expect(find.text('Wawasan'), findsOneWidget);
    expect(find.text('Lainnya'), findsOneWidget);
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

  testWidgets('feature screens follow the platform dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());

    // The home shell uses a fixed Sky palette, but the feature surfaces reached
    // via "Lainnya" still honour the platform brightness.
    await tester.tap(find.text('Lainnya'));
    await tester.pumpAndSettle();

    final settingsContext = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(settingsContext).brightness, Brightness.dark);
    expect(
      settingsContext.affluenaColors.surfaceCanvas,
      AffluenaColors.darkCanvas,
    );
  });
}
