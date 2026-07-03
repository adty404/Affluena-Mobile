import 'package:flutter/material.dart';

import '../../../../app/theme/affluena_theme.dart';
import '../../../categories/data/category_models.dart';

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

/// The icon-tile variant for rows painted **in** the item's color (the solid
/// list-card treatment mirroring Beranda's dashboard cards): a white glyph on
/// a translucent-white square, so the icon stays legible on any palette
/// swatch. Pair with white title/value text and `StatusBadge(onColor: true)`.
class ItemOnColorIconTile extends StatelessWidget {
  const ItemOnColorIconTile({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AffluenaRadii.md),
      ),
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }
}

/// One entry in the category icon catalog: the semantic id persisted on the
/// API, a short Indonesian label for pickers, and the Material glyph both
/// clients render for that id.
class CategoryIconOption {
  const CategoryIconOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

/// The client-owned category icon catalog (semantic id -> Material icon).
/// Ids are persisted as-is on the API (`icon` is a free-form string there), so
/// never rename an id — add a new one instead. Keep in sync with the web
/// catalog when it is added.
const List<CategoryIconOption> kCategoryIconCatalog = <CategoryIconOption>[
  CategoryIconOption(
    id: 'food',
    label: 'Makanan',
    icon: Icons.restaurant_outlined,
  ),
  CategoryIconOption(
    id: 'groceries',
    label: 'Belanja harian',
    icon: Icons.local_grocery_store_outlined,
  ),
  CategoryIconOption(
    id: 'transport',
    label: 'Transportasi',
    icon: Icons.directions_car_outlined,
  ),
  CategoryIconOption(id: 'home', label: 'Rumah', icon: Icons.home_outlined),
  CategoryIconOption(
    id: 'bills',
    label: 'Tagihan',
    icon: Icons.receipt_long_outlined,
  ),
  CategoryIconOption(
    id: 'shopping',
    label: 'Belanja',
    icon: Icons.shopping_bag_outlined,
  ),
  CategoryIconOption(
    id: 'health',
    label: 'Kesehatan',
    icon: Icons.favorite_outline,
  ),
  CategoryIconOption(
    id: 'education',
    label: 'Pendidikan',
    icon: Icons.school_outlined,
  ),
  CategoryIconOption(
    id: 'entertainment',
    label: 'Hiburan',
    icon: Icons.movie_outlined,
  ),
  CategoryIconOption(
    id: 'travel',
    label: 'Perjalanan',
    icon: Icons.flight_outlined,
  ),
  CategoryIconOption(id: 'pets', label: 'Peliharaan', icon: Icons.pets),
  CategoryIconOption(
    id: 'kids',
    label: 'Anak',
    icon: Icons.child_care_outlined,
  ),
  CategoryIconOption(id: 'work', label: 'Pekerjaan', icon: Icons.work_outline),
  CategoryIconOption(
    id: 'salary',
    label: 'Gaji',
    icon: Icons.payments_outlined,
  ),
  CategoryIconOption(
    id: 'gift',
    label: 'Hadiah',
    icon: Icons.card_giftcard_outlined,
  ),
  CategoryIconOption(
    id: 'savings',
    label: 'Tabungan',
    icon: Icons.savings_outlined,
  ),
  CategoryIconOption(
    id: 'investment',
    label: 'Investasi',
    icon: Icons.show_chart,
  ),
  CategoryIconOption(
    id: 'phone',
    label: 'Pulsa & internet',
    icon: Icons.wifi_outlined,
  ),
  CategoryIconOption(
    id: 'sports',
    label: 'Olahraga',
    icon: Icons.fitness_center_outlined,
  ),
  CategoryIconOption(
    id: 'misc',
    label: 'Lainnya',
    icon: Icons.category_outlined,
  ),
];

/// The catalog glyph for a stored semantic id, or null when the id is empty or
/// unknown (e.g. saved by a newer client) so callers can fall back.
IconData? categoryIconFor(String id) {
  if (id.isEmpty) return null;
  for (final option in kCategoryIconCatalog) {
    if (option.id == id) return option.icon;
  }
  return null;
}

/// Semantic wallet icon ids a user can choose, mapped to Material icons. The
/// id (the map key) is what gets persisted; never persist the [IconData].
/// Lives here (not in the wallets feature) so [entityIconFor] can union it
/// with the category catalog without a feature import; `wallet_appearance.dart`
/// re-exports it for the historical wallet-named call sites.
const Map<String, IconData> kWalletIconCatalog = <String, IconData>{
  'wallet': Icons.account_balance_wallet_outlined,
  'bank': Icons.account_balance_outlined,
  'cash': Icons.payments_outlined,
  'card': Icons.credit_card_outlined,
  'ewallet': Icons.phone_iphone_outlined,
  'savings': Icons.savings_outlined,
  'investment': Icons.trending_up,
  'gift': Icons.card_giftcard_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'food': Icons.restaurant_outlined,
  'transport': Icons.directions_car_outlined,
  'home': Icons.home_outlined,
  'health': Icons.favorite_outline,
  'travel': Icons.flight_outlined,
};

/// The glyph for a stored *entity* icon id (budgets, goals, installments,
/// subscriptions, recurring rules): looked up against the union of
/// [kCategoryIconCatalog] + [kWalletIconCatalog], the category catalog winning
/// on an id clash so both clients resolve the same glyph. Returns null when
/// the id is empty or unknown (e.g. saved by a newer client) so callers can
/// fall back. Wallets keep `resolveWalletIcon` (per-type default fallback).
IconData? entityIconFor(String icon) {
  if (icon.isEmpty) return null;
  return categoryIconFor(icon) ?? kWalletIconCatalog[icon];
}

/// The glyph to render for an entity: its own stored icon when set and known,
/// otherwise [fallback] (the surface's existing default glyph).
IconData resolveEntityIcon(String icon, IconData fallback) {
  return entityIconFor(icon) ?? fallback;
}

/// Resolves the glyph shown for [type] when a category has no chosen icon.
IconData categoryTypeFallbackIcon(CategoryType type) {
  return switch (type) {
    CategoryType.income => Icons.trending_up,
    CategoryType.expense => Icons.trending_down,
  };
}

/// The glyph to render for [category]: its chosen catalog icon when set and
/// known, otherwise the income/expense default glyph.
IconData resolveCategoryIcon(Category category) {
  return categoryIconFor(category.icon) ??
      categoryTypeFallbackIcon(category.type);
}

/// An icon-picker grid over [kCategoryIconCatalog] plus a leading "default"
/// option (no icon: the category keeps its income/expense glyph). Each cell is
/// keyed `category-icon-<id>` (the default option is `category-icon-none`) so
/// hermetic tests can target a specific choice. The selected cell renders in a
/// filled accent state — tinted with [accentHex] when the user has picked a
/// color, so the form previews the final appearance.
class CategoryIconPickerGrid extends StatelessWidget {
  const CategoryIconPickerGrid({
    required this.selected,
    required this.onChanged,
    required this.fallbackIcon,
    this.accentHex,
    this.enabled = true,
    super.key,
  });

  /// Currently selected semantic id (null or empty = default glyph).
  final String? selected;
  final ValueChanged<String?> onChanged;

  /// Glyph rendered inside the leading "default" cell.
  final IconData fallbackIcon;

  /// The category's chosen color, used to tint the selected fill.
  final String? accentHex;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.affluenaColors;
    final custom = parseItemColor(accentHex ?? '');
    final accent = custom ?? colors.ink;
    // White is safe on every palette swatch; on the ink accent (which flips to
    // white in dark mode) use the elevated surface for contrast instead.
    final onAccent = custom != null ? Colors.white : colors.surfaceElevated;
    final noneSelected = selected == null || selected!.isEmpty;

    Widget cell({
      required Key key,
      required IconData icon,
      required bool isSelected,
      required VoidCallback onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          key: key,
          onTap: enabled ? onTap : null,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? accent : colors.surfaceElevated,
              borderRadius: BorderRadius.circular(AffluenaRadii.md),
              border: Border.all(
                color: isSelected ? accent : colors.borderSubtle,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? onAccent : colors.inkMuted,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: AffluenaSpacing.space2,
      runSpacing: AffluenaSpacing.space2,
      children: [
        cell(
          key: const Key('category-icon-none'),
          icon: fallbackIcon,
          isSelected: noneSelected,
          onTap: () => onChanged(null),
          tooltip: 'Ikon bawaan',
        ),
        for (final option in kCategoryIconCatalog)
          cell(
            key: Key('category-icon-${option.id}'),
            icon: option.icon,
            isSelected: selected == option.id,
            onTap: () => onChanged(option.id),
            tooltip: option.label,
          ),
      ],
    );
  }
}
