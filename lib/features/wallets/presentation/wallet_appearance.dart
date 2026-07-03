import 'package:flutter/material.dart';

import '../../shared/presentation/appearance/item_appearance.dart';
import '../data/wallet_models.dart';
import 'wallet_format.dart';

export '../../shared/presentation/appearance/item_appearance.dart';

/// Wallet appearance catalog: the curated color palette + icon set a user can
/// pick from when creating/editing a wallet. The color palette, hex parsing,
/// and the wallet icon catalog itself now live in the shared item-appearance
/// module (budgets, goals, trackers, and recurring rules share the swatches,
/// and `entityIconFor` unions the wallet catalog with the category catalog);
/// this file keeps the historical wallet-named aliases so existing call sites
/// keep working. The chosen values are persisted on the API as plain strings
/// (`color` = hex, `icon` = a semantic id from [kWalletIconCatalog]); the
/// catalog itself lives client-side so web + mobile can map the same id to
/// their own icon set. Keep these in sync with the web catalog when it is
/// added.

/// Historical alias for [kItemColorPalette].
const List<String> kWalletColorPalette = kItemColorPalette;

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
