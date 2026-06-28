import 'package:flutter/material.dart';

/// Sky & Denim — the app's palette.
///
/// The redesign surfaces reference these tokens directly; the themed feature
/// screens reach the same colours through [AffluenaColors] /
/// [AffluenaSemanticColors], whose light tokens now resolve to this palette
/// (dark mode uses a cool Sky-flavoured variant). The old warm-paper palette
/// has been fully retired.
abstract final class SkyPalette {
  static const ground = Color(0xFFEEF3F8);
  static const surface = Color(0xFFFFFFFF);
  static const sheet = Color(0xFFF4F8FC);
  static const line = Color(0xFFE0E8F0);
  static const ink = Color(0xFF1E2A38);
  static const muted = Color(0xFF6B7B8C);
  static const faint = Color(0xFF9FB0C0);
  static const accent = Color(0xFF3E72B8);
  static const accentSoft = Color(0xFFE6EFF8);
  static const accentSoftBorder = Color(0xFFD3E2F1);
  static const accentInk = Color(0xFF2F5C97);

  /// Member avatars (owner / partner). Initials render in white.
  static const avatarPrimary = Color(0xFF3E72B8);
  static const avatarSecondary = Color(0xFF5E6E80);

  /// Semantic colours, kept separate from [accent] so status stays legible.
  static const income = Color(0xFF2E8B57);
  static const danger = Color(0xFFC2553F);
}

/// Brightness-resolved Sky & Denim colours. [SkyPalette] holds the light
/// constants; this resolves the right value for the active theme so the
/// redesign surfaces respect dark mode. Read it via `context.sky`.
///
/// The light set is identical to [SkyPalette]; the dark set is a cool,
/// Sky-flavoured dark that matches the dark `AffluenaColors` used by the
/// themed feature screens, so the whole app stays consistent in either mode.
@immutable
class SkyColors {
  const SkyColors({
    required this.ground,
    required this.surface,
    required this.sheet,
    required this.line,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.accentSoftBorder,
    required this.accentInk,
    required this.avatarPrimary,
    required this.avatarSecondary,
    required this.income,
    required this.danger,
  });

  final Color ground;
  final Color surface;
  final Color sheet;
  final Color line;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color accentSoft;
  final Color accentSoftBorder;
  final Color accentInk;
  final Color avatarPrimary;
  final Color avatarSecondary;
  final Color income;
  final Color danger;

  static const light = SkyColors(
    ground: SkyPalette.ground,
    surface: SkyPalette.surface,
    sheet: SkyPalette.sheet,
    line: SkyPalette.line,
    ink: SkyPalette.ink,
    muted: SkyPalette.muted,
    faint: SkyPalette.faint,
    accent: SkyPalette.accent,
    accentSoft: SkyPalette.accentSoft,
    accentSoftBorder: SkyPalette.accentSoftBorder,
    accentInk: SkyPalette.accentInk,
    avatarPrimary: SkyPalette.avatarPrimary,
    avatarSecondary: SkyPalette.avatarSecondary,
    income: SkyPalette.income,
    danger: SkyPalette.danger,
  );

  static const dark = SkyColors(
    ground: Color(0xFF0F1822),
    surface: Color(0xFF16212E),
    sheet: Color(0xFF1C2A39),
    line: Color(0xFF2A3A48),
    ink: Color(0xFFE8EEF4),
    muted: Color(0xFF9FB0C0),
    faint: Color(0xFF6E7E8E),
    accent: Color(0xFF6BA0D8),
    accentSoft: Color(0xFF1E3147),
    accentSoftBorder: Color(0xFF34527A),
    accentInk: Color(0xFFA9C8E8),
    avatarPrimary: Color(0xFF4E82C8),
    avatarSecondary: Color(0xFF7E8EA0),
    income: Color(0xFF6BC089),
    danger: Color(0xFFE08070),
  );

  static SkyColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

extension SkyColorsContext on BuildContext {
  /// The Sky & Denim colours for the active theme brightness.
  SkyColors get sky => SkyColors.of(this);
}
