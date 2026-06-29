import 'package:flutter/material.dart';

import '../data/wallet_models.dart';
import 'wallet_format.dart';

/// Wallet appearance catalog: the curated color palette + icon set a user can
/// pick from when creating/editing a wallet. The chosen values are persisted on
/// the API as plain strings (`color` = hex, `icon` = a semantic id from
/// [kWalletIconCatalog]); the catalog itself lives client-side so web + mobile
/// can map the same id to their own icon set. Keep these in sync with the web
/// catalog when it is added.

/// Curated swatches that sit well within the "Sky & Denim" palette. Stored as
/// uppercase `#RRGGBB` hex strings (the value sent to / received from the API).
const List<String> kWalletColorPalette = <String>[
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

/// Semantic icon ids a user can choose, mapped to Material icons. The id (the
/// map key) is what gets persisted; never persist the [IconData].
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

/// Parses a `#RRGGBB` (or `RRGGBB`) hex string into a [Color]. Returns null for
/// anything it cannot parse, so callers can fall back to a theme color.
Color? parseWalletColor(String hex) {
  var value = hex.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length != 6) return null;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}

/// The accent color for a wallet: its chosen [Wallet.color] if set and valid,
/// otherwise [fallback] (the theme accent), so wallets without a color keep
/// rendering exactly as before.
Color resolveWalletColor(String colorHex, Color fallback) {
  return parseWalletColor(colorHex) ?? fallback;
}

/// The icon for a wallet: its chosen [Wallet.icon] if set and known, otherwise
/// the default icon derived from its [WalletType].
IconData resolveWalletIcon(Wallet wallet) {
  return resolveWalletIconId(wallet.icon, wallet.type);
}

/// Resolves an icon id (may be empty) to an [IconData], falling back to the
/// per-type default. Used by the picker preview before a wallet exists.
IconData resolveWalletIconId(String iconId, WalletType type) {
  return kWalletIconCatalog[iconId] ?? walletIcon(type);
}
