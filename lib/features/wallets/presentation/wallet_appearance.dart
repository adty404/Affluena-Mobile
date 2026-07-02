import 'package:flutter/material.dart';

import '../../shared/presentation/appearance/item_appearance.dart';
import '../data/wallet_models.dart';
import 'wallet_format.dart';

export '../../shared/presentation/appearance/item_appearance.dart';

/// Wallet appearance catalog: the curated color palette + icon set a user can
/// pick from when creating/editing a wallet. The color palette and hex parsing
/// now live in the shared item-appearance module (budgets, goals, trackers,
/// and recurring rules share the same swatches); this file keeps the
/// wallet-specific icon catalog plus the historical wallet-named aliases so
/// existing call sites keep working. The chosen values are persisted on the
/// API as plain strings (`color` = hex, `icon` = a semantic id from
/// [kWalletIconCatalog]); the catalog itself lives client-side so web + mobile
/// can map the same id to their own icon set. Keep these in sync with the web
/// catalog when it is added.

/// Historical alias for [kItemColorPalette].
const List<String> kWalletColorPalette = kItemColorPalette;

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

/// Historical alias for [parseItemColor].
Color? parseWalletColor(String hex) => parseItemColor(hex);

/// Historical alias for [resolveItemColor]: the accent color for a wallet is
/// its chosen [Wallet.color] if set and valid, otherwise [fallback].
Color resolveWalletColor(String colorHex, Color fallback) {
  return resolveItemColor(colorHex, fallback);
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
