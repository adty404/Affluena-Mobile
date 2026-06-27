import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/auth_test_helpers.dart';

/// Per-tab design snapshots. See home_golden_test.dart for the rationale.
/// Baselines generated with `flutter test --update-goldens` on this machine.
void main() {
  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpAuthTestApp(tester, tokenStore: authenticatedTokenStore());
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wallets tab golden', (tester) async {
    await openTab(tester, 'Wallets');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/wallets.png'),
    );
  });

  testWidgets('add tab golden', (tester) async {
    await openTab(tester, 'Add');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/add.png'),
    );
  });

  testWidgets('activity tab golden', (tester) async {
    await openTab(tester, 'Activity');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/activity.png'),
    );
  });

  testWidgets('more tab golden', (tester) async {
    await openTab(tester, 'More');
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/more.png'),
    );
  });
}
