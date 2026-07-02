import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../../app/theme/sky_palette.dart';

/// The app's standard single-select pill chip (the look used by the Transaksi
/// type filters): a stadium pill that fills with the brand accent when
/// selected and stays the same size whether selected or not. Pass a null
/// [onSelected] to render it disabled.
class AffluenaChoiceChip extends StatelessWidget {
  const AffluenaChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;

  /// Fired when tapped. Null renders the chip disabled (dimmed, not tappable).
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final enabled = onSelected != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: selected ? colors.forest : colors.surfaceTintSoft,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? colors.forest : colors.borderSubtle,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AffluenaSpacing.space4,
              vertical: AffluenaSpacing.space2,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? context.sky.onAccent : colors.inkMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
