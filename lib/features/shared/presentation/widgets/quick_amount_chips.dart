import 'package:flutter/material.dart';

import '../../../../core/haptics.dart';
import 'affluena_chip_bar.dart';
import 'affluena_choice_chip.dart';

/// The standard quick-amount presets shown beside money-entry fields, in
/// minor units (whole rupiah).
const List<int> kQuickAmountPresets = [10000, 50000, 100000, 500000, 1000000];

/// One-tap amount presets (`10rb · 50rb · 100rb · 500rb · 1jt`) rendered as
/// the app-standard [AffluenaChipBar] of [AffluenaChoiceChip]s. Tapping a chip
/// SETS the amount (replaces — never adds) and ticks a selection haptic; the
/// chip whose value equals the current amount renders selected. Keys:
/// `amount-chip-<minor>` (e.g. `amount-chip-50000`).
class QuickAmountChips extends StatelessWidget {
  const QuickAmountChips({
    required this.onSelected,
    this.selectedMinor,
    this.enabled = true,
    this.amounts = kQuickAmountPresets,
    super.key,
  });

  /// Fired with the tapped preset's minor-unit value.
  final ValueChanged<int> onSelected;

  /// The current amount, so the matching chip renders selected.
  final int? selectedMinor;
  final bool enabled;
  final List<int> amounts;

  /// `10000 → 10rb`, `1000000 → 1jt` — the compact labels users read fastest.
  static String label(int minor) {
    if (minor % 1000000 == 0) return '${minor ~/ 1000000}jt';
    if (minor % 1000 == 0) return '${minor ~/ 1000}rb';
    return '$minor';
  }

  @override
  Widget build(BuildContext context) {
    return AffluenaChipBar(
      chips: [
        for (final minor in amounts)
          AffluenaChoiceChip(
            key: Key('amount-chip-$minor'),
            label: label(minor),
            selected: selectedMinor == minor,
            onSelected: enabled
                ? () {
                    hapticTap();
                    onSelected(minor);
                  }
                : null,
          ),
      ],
    );
  }
}
