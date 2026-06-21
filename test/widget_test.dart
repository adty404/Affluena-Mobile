import 'package:affluena_mobile/app/affluena_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders Affluena dashboard shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AffluenaApp()));

    expect(find.text('Affluena'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Total balance'), findsOneWidget);
  });

  testWidgets('navigates to quick entry from bottom nav', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AffluenaApp()));

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
