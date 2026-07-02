import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';

/// Shared item-appearance catalog: the curated color palette a user can pick
/// from when creating/editing a wallet, budget, goal, installment,
/// subscription, or recurring rule. The chosen value is persisted on the API
/// as a plain `#RRGGBB` hex string; missing/empty means "no color" so every
/// surface must fall back to its default theming. Keep the palette in sync
/// with the web catalog when it is added.

/// Curated swatches that sit well within the "Sky & Denim" palette. Stored as
/// uppercase `#RRGGBB` hex strings (the value sent to / received from the API).
const List<String> kItemColorPalette = <String>[
  '#3E72B8', // denim (accent)
  '#2BB3A3', // teal
  '#2E8B57', // green
  '#E0A23B', // amber
  '#C2553F', // coral
  '#7C5BC2', // purple
  '#4256B8', // indigo
  '#C2588A', // pink
  '#5E6E80', // slate
  '#9E7B4F', // bronze
];

/// Parses a `#RRGGBB` (or `RRGGBB`) hex string into a [Color]. Returns null for
/// anything it cannot parse, so callers can fall back to a theme color.
Color? parseItemColor(String hex) {
  var value = hex.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length != 6) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}

/// The accent color for an item: its chosen color if set and valid, otherwise
/// [fallback] (the theme accent), so items without a color keep rendering
/// exactly as before.
Color resolveItemColor(String colorHex, Color fallback) {
  return parseItemColor(colorHex) ?? fallback;
}

/// A horizontal swatch-picker row over [kItemColorPalette] plus a leading
/// "no color" (default) option. Each swatch is keyed `<entity>-color-$hex`
/// (the default option is `<entity>-color-none`) so hermetic tests can target
/// a specific choice per entity.
///
/// [selected] is the current hex (null or empty = no color); [onChanged]
/// receives the tapped hex, or null when the default option is chosen.
class ItemColorPickerRow extends StatelessWidget {
  const ItemColorPickerRow({
    required this.entity,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Key prefix, e.g. 'wallet' -> `wallet-color-#2E8B57`.
  final String entity;
  final String? selected;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final noneSelected = selected == null || selected!.isEmpty;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kItemColorPalette.length + 1,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AffluenaSpacing.space3),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "No color": keep the entity on its default theming.
            return GestureDetector(
              key: Key('$entity-color-none'),
              onTap: enabled ? () => onChanged(null) : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: noneSelected ? colors.ink : colors.borderSubtle,
                    width: noneSelected ? 2.5 : 1,
                  ),
                ),
                child: Icon(
                  Icons.format_color_reset_outlined,
                  color: colors.inkMuted,
                  size: 18,
                ),
              ),
            );
          }
          final hex = kItemColorPalette[index - 1];
          final color = resolveItemColor(hex, colors.forest);
          final isSelected = selected == hex;
          return GestureDetector(
            key: Key('$entity-color-$hex'),
            onTap: enabled ? () => onChanged(hex) : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.ink : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}

/// A rounded icon tile carrying an item's accent — used by list-screen rows
/// the way the wallets grid colors its wallet cards: the accent is the item's
/// chosen color when valid, otherwise [fallback], with a soft translucent
/// background derived from it.
class ItemAccentIconTile extends StatelessWidget {
  const ItemAccentIconTile({
    required this.icon,
    required this.colorHex,
    required this.fallback,
    this.fallbackBackground,
    super.key,
  });

  final IconData icon;

  /// The item's stored color; empty/invalid falls back to [fallback].
  final String colorHex;
  final Color fallback;

  /// Background when no valid color is set; defaults to a soft [fallback].
  final Color? fallbackBackground;

  @override
  Widget build(BuildContext context) {
    final custom = parseItemColor(colorHex);
    final accent = custom ?? fallback;
    final background = custom != null
        ? custom.withValues(alpha: 0.14)
        : (fallbackBackground ?? fallback.withValues(alpha: 0.14));
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AffluenaRadii.md),
      ),
      child: Icon(icon, size: 20, color: accent),
    );
  }
}
