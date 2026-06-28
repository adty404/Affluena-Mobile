@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_helpers.dart';

/// Golden (design-snapshot) test of the redesign home shell — the Spaces
/// "rooms" home that is now the authenticated default. Freezes the current
/// rendered look so a behavior-preserving refactor that accidentally shifts the
/// UI is caught. Baseline generated on this machine with
/// `flutter test --update-goldens` and compared on re-run.
///
/// Note: goldens render with the test default font (no bundled app font), so
/// they are a drift detector across refactors — not a pixel match of the device.
void main() {
  testWidgets('home shell golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_beranda.png'),
    );
  });

  testWidgets('home shell golden (dark)', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());
    await tester.pumpAndSettle();

    // The redesign surfaces resolve colours via `context.sky`, so dark mode
    // renders the cool Sky-flavoured dark palette rather than staying light.
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_beranda_dark.png'),
    );
  });
}
