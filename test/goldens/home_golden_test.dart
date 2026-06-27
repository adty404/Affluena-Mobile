import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_helpers.dart';

/// Golden (design-snapshot) tests. These freeze the *current* rendered look of
/// key screens so a behavior-preserving refactor that accidentally shifts the
/// UI is caught immediately. Baselines are generated on this machine with
/// `flutter test --update-goldens` and compared on re-run.
///
/// Note: goldens render with the test default font (no bundled app font), so
/// they are a drift detector across refactors — not a pixel match of the device.
void main() {
  testWidgets('home dashboard golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // The dashboard header greeting is time-of-day dependent
    // (_greetingForNow). Freeze the clock at a morning hour so the golden is
    // stable regardless of when the suite runs.
    await withClock(Clock.fixed(DateTime(2026, 6, 25, 9)), () async {
      await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_dashboard.png'),
      );
    });
  });
}
