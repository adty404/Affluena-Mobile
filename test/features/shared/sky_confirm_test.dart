import 'package:affluena_mobile/app/theme/affluena_theme.dart';
import 'package:affluena_mobile/app/theme/sky_palette.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/sky_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a screen with a trigger button that opens [skyConfirm] and records
/// the returned value into [results].
Future<void> _pumpHost(
  WidgetTester tester,
  List<bool> results, {
  bool danger = false,
  IconData? icon,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AffluenaTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                results.add(
                  await skyConfirm(
                    context,
                    title: 'Hapus item ini?',
                    message: 'Tindakan ini tidak dapat dibatalkan.',
                    confirmLabel: 'Hapus',
                    cancelLabel: 'Batal',
                    danger: danger,
                    icon: icon,
                  ),
                );
              },
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('buka'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders as a bottom sheet with title, message, and actions', (
    tester,
  ) async {
    final results = <bool>[];
    await _pumpHost(tester, results);

    // It is a modal bottom sheet, not an AlertDialog.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    expect(find.text('Hapus item ini?'), findsOneWidget);
    expect(find.text('Tindakan ini tidak dapat dibatalkan.'), findsOneWidget);
    expect(find.byKey(const Key('sky-confirm-accept')), findsOneWidget);
    expect(find.byKey(const Key('sky-confirm-cancel')), findsOneWidget);

    // Default (non-danger) variant: accent tile with the question glyph and
    // the theme's default FilledButton style.
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    final accept = tester.widget<FilledButton>(
      find.byKey(const Key('sky-confirm-accept')),
    );
    expect(
      accept.style?.backgroundColor?.resolve(const {}),
      isNot(SkyPalette.danger),
    );

    await tester.tap(find.byKey(const Key('sky-confirm-accept')));
    await tester.pumpAndSettle();
    expect(results, [true]);
    expect(find.text('Hapus item ini?'), findsNothing);
  });

  testWidgets('cancel and barrier dismiss both return false', (tester) async {
    final results = <bool>[];
    await _pumpHost(tester, results);

    await tester.tap(find.byKey(const Key('sky-confirm-cancel')));
    await tester.pumpAndSettle();
    expect(results, [false]);

    // Dismissing the sheet without choosing also counts as cancel.
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(results, [false, false]);
  });

  testWidgets('danger variant paints the confirm action and tile coral', (
    tester,
  ) async {
    final results = <bool>[];
    await _pumpHost(tester, results, danger: true);

    // Danger defaults to the warning glyph, tinted coral.
    final glyph = tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded));
    expect(glyph.color, SkyPalette.danger);

    final accept = tester.widget<FilledButton>(
      find.byKey(const Key('sky-confirm-accept')),
    );
    expect(accept.style?.backgroundColor?.resolve(const {}), SkyPalette.danger);
  });

  testWidgets('a custom icon overrides the default glyph', (tester) async {
    final results = <bool>[];
    await _pumpHost(tester, results, danger: true, icon: Icons.delete_outline);

    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });
}
