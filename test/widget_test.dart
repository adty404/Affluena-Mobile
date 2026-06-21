import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
