import 'package:affluena_mobile/app/theme/sky_palette.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/sky_avatar.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/sky_keypad.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/sky_progress_bar.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/sky_room_card.dart';
import 'package:affluena_mobile/features/shared/presentation/widgets/sky_segmented_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  test('Sky & Denim tokens are locked', () {
    expect(SkyPalette.accent, const Color(0xFF3E72B8));
    expect(SkyPalette.ground, const Color(0xFFEEF3F8));
    expect(SkyPalette.ink, const Color(0xFF1E2A38));
    expect(SkyPalette.income, const Color(0xFF2E8B57));
  });

  testWidgets('SkyAvatar renders its initial', (tester) async {
    await _pump(tester, const SkyAvatar(initial: 'A'));
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('SkySegmentedToggle fires onChanged for the tapped option', (
    tester,
  ) async {
    String? picked;
    await _pump(
      tester,
      SkySegmentedToggle<String>(
        options: const [
          SkySegmentOption(value: 'out', label: 'Pengeluaran'),
          SkySegmentOption(value: 'in', label: 'Pemasukan'),
        ],
        selected: 'out',
        onChanged: (value) => picked = value,
      ),
    );

    await tester.tap(find.text('Pemasukan'));
    expect(picked, 'in');
  });

  testWidgets('SkySegmentedToggle ignores taps when disabled', (tester) async {
    var changed = false;
    await _pump(
      tester,
      SkySegmentedToggle<String>(
        options: const [
          SkySegmentOption(value: 'out', label: 'Pengeluaran'),
          SkySegmentOption(value: 'in', label: 'Pemasukan'),
        ],
        selected: 'out',
        enabled: false,
        onChanged: (_) => changed = true,
      ),
    );

    await tester.tap(find.text('Pemasukan'));
    expect(changed, isFalse);
  });

  testWidgets('SkyProgressBar clamps its fill width', (tester) async {
    await _pump(
      tester,
      const SizedBox(width: 200, child: SkyProgressBar(value: 1.6)),
    );
    final fraction = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fraction.widthFactor, 1.0);
  });

  testWidgets('SkyKeypad emits digit taps and backspace', (tester) async {
    final keys = <String>[];
    var backspaces = 0;
    await _pump(
      tester,
      SizedBox(
        width: 280,
        child: SkyKeypad(onKey: keys.add, onBackspace: () => backspaces++),
      ),
    );

    await tester.tap(find.text('7'));
    await tester.tap(find.text('000'));
    await tester.tap(find.byKey(const Key('sky-keypad-backspace')));

    expect(keys, ['7', '000']);
    expect(backspaces, 1);
  });

  testWidgets('SkyRoomCard shows content and handles tap + long-press', (
    tester,
  ) async {
    var taps = 0;
    var longPresses = 0;
    await _pump(
      tester,
      SkyRoomCard(
        leading: const SkyAvatar(initial: 'A'),
        title: 'Dompet Main',
        subtitle: 'Nonton berdua · hari ini',
        badge: const Text('BERSAMA'),
        trailing: const Text('Rp 1.250.000'),
        footer: const SkyProgressBar(value: 0.62),
        shared: true,
        onTap: () => taps++,
        onLongPress: () => longPresses++,
      ),
    );

    expect(find.text('Dompet Main'), findsOneWidget);
    expect(find.text('Nonton berdua · hari ini'), findsOneWidget);
    expect(find.text('BERSAMA'), findsOneWidget);
    expect(find.text('Rp 1.250.000'), findsOneWidget);
    expect(find.byType(SkyProgressBar), findsOneWidget);

    await tester.tap(find.text('Dompet Main'));
    await tester.longPress(find.text('Dompet Main'));
    expect(taps, 1);
    expect(longPresses, 1);
  });
}
