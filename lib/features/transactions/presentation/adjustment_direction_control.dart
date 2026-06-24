import 'package:flutter/material.dart';

import '../../../app/theme/affluena_theme.dart';

/// Segmented toggle that lets the user record an adjustment that either
/// increases (positive `amount_minor`) or decreases (negative `amount_minor`)
/// a wallet balance.
///
/// Mirrors the [ChoiceChip] style used by the transaction type selector:
/// "Increase (+)" leans on the forest/success tone, "Decrease (−)" on coral.
class AdjustmentDirectionControl extends StatelessWidget {
  const AdjustmentDirectionControl({
    required this.decrease,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  /// `true` when the "Decrease (−)" option is selected.
  final bool decrease;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return Wrap(
      spacing: AffluenaSpacing.space2,
      runSpacing: AffluenaSpacing.space2,
      children: [
        _DirectionChip(
          key: const Key('adjustment-direction-increase'),
          label: 'Increase (+)',
          selected: !decrease,
          enabled: enabled,
          selectedColor: colors.forestSoft,
          selectedForeground: colors.success,
          onSelected: () => onChanged(false),
        ),
        _DirectionChip(
          key: const Key('adjustment-direction-decrease'),
          label: 'Decrease (−)',
          selected: decrease,
          enabled: enabled,
          selectedColor: colors.coral.withAlpha(36),
          selectedForeground: colors.coral,
          onSelected: () => onChanged(true),
        ),
      ],
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.selectedColor,
    required this.selectedForeground,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final Color selectedColor;
  final Color selectedForeground;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      avatar: selected ? Icon(Icons.check, size: 16, color: selectedForeground) : null,
      selectedColor: selectedColor,
      labelStyle: TextStyle(
        color: selected ? selectedForeground : colors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: selected ? selectedForeground : colors.borderSubtle),
      onSelected: enabled ? (_) => onSelected() : null,
    );
  }
}
