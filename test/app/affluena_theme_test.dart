import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semantic theme tokens follow light and dark palettes', () {
    final lightColors = AffluenaTheme.light
        .extension<AffluenaSemanticColors>()!;
    final darkColors = AffluenaTheme.dark.extension<AffluenaSemanticColors>()!;

    expect(lightColors.surfaceCanvas, AffluenaColors.surfaceCanvas);
    expect(lightColors.surfaceTintSoft, AffluenaColors.surfaceTintSoft);
    expect(lightColors.forestSoft, AffluenaColors.forestSoft);

    expect(darkColors.surfaceCanvas, AffluenaColors.darkCanvas);
    expect(darkColors.surfaceTintSoft, AffluenaColors.darkSurfaceTintSoft);
    expect(darkColors.forestSoft, AffluenaColors.darkForestSoft);
    expect(darkColors.ink, AffluenaColors.darkInk);
    expect(darkColors.borderSubtle, AffluenaColors.darkBorderSubtle);
  });

  test('dark chip and navigation colors do not reuse light fills', () {
    final darkTheme = AffluenaTheme.dark;
    final darkColors = darkTheme.extension<AffluenaSemanticColors>()!;

    expect(darkTheme.chipTheme.backgroundColor, darkColors.surfaceTintSoft);
    expect(darkTheme.chipTheme.selectedColor, darkColors.forestSoft);
    expect(darkTheme.navigationBarTheme.indicatorColor, darkColors.forestSoft);
    expect(
      darkTheme.navigationBarTheme.indicatorColor,
      isNot(AffluenaColors.forestSoft),
    );
  });

  testWidgets('MaterialApp resolves the dark theme from platform brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    late AffluenaSemanticColors resolvedColors;
    await tester.pumpWidget(
      MaterialApp(
        theme: AffluenaTheme.light,
        darkTheme: AffluenaTheme.dark,
        home: Builder(
          builder: (context) {
            resolvedColors = context.affluenaColors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolvedColors.surfaceCanvas, AffluenaColors.darkCanvas);
    expect(resolvedColors.ink, AffluenaColors.darkInk);
  });

  testWidgets('semantic colors fall back to Theme brightness', (tester) async {
    late AffluenaSemanticColors resolvedColors;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            resolvedColors = context.affluenaColors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolvedColors.surfaceSoft, AffluenaColors.darkSurface);
    expect(resolvedColors.forestSoft, AffluenaColors.darkForestSoft);
  });
}
