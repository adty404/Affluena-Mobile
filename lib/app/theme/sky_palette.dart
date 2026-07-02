import 'package:flutter/material.dart';

/// Tinta — the app's monochrome ink palette.
///
/// The UI chrome is black-and-white: neutral greys, near-black ink, and an
/// accent that IS the ink (white in dark mode). Colour is reserved for
/// meaning — [income], [danger], and the amber warning in `AffluenaColors` —
/// plus user-chosen content colours (e.g. wallet colours). The redesign
/// surfaces reference these tokens directly; the themed feature screens reach
/// the same colours through [AffluenaColors] / [AffluenaSemanticColors],
/// whose light tokens resolve to this palette. The previous Sky & Denim
/// (denim-blue) palette has been retired; token names are kept.
abstract final class SkyPalette {
  static const ground = Color(0xFFF7F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const sheet = Color(0xFFF1F1EF);
  static const line = Color(0xFFE5E5E3);
  static const ink = Color(0xFF17181A);
  static const muted = Color(0xFF6E7073);
  static const faint = Color(0xFFA4A5A8);
  static const accent = Color(0xFF17181A);
  static const accentSoft = Color(0xFFECECEA);
  static const accentSoftBorder = Color(0xFFDCDCDA);
  static const accentInk = Color(0xFF17181A);

  /// Foreground for content sitting ON an [accent] fill (FAB icon, selected
  /// chip label). White here; the dark set flips it to near-black because the
  /// dark accent is white. Never hardcode `Colors.white` on an accent fill.
  static const onAccent = Color(0xFFFFFFFF);

  /// Member avatars (owner / partner). Initials render in white, so both
  /// tones stay dark enough for white text in either mode.
  static const avatarPrimary = Color(0xFF17181A);
  static const avatarSecondary = Color(0xFF77797D);

  /// Semantic colours — the only colour in the UI chrome, kept separate from
  /// [accent] so money and status stay scannable in a monochrome interface.
  static const income = Color(0xFF2E8B57);
  static const danger = Color(0xFFC2553F);
}

/// Brightness-resolved Tinta colours. [SkyPalette] holds the light constants;
/// this resolves the right value for the active theme so the redesign
/// surfaces respect dark mode. Read it via `context.sky`.
///
/// The light set is identical to [SkyPalette]; the dark set is the inverted
/// ink scheme (near-black grounds, white ink/accent) that matches the dark
/// `AffluenaColors` used by the themed feature screens, so the whole app
/// stays consistent in either mode.
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
    required this.onAccent,
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
  final Color onAccent;
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
    onAccent: SkyPalette.onAccent,
    avatarPrimary: SkyPalette.avatarPrimary,
    avatarSecondary: SkyPalette.avatarSecondary,
    income: SkyPalette.income,
    danger: SkyPalette.danger,
  );

  static const dark = SkyColors(
    ground: Color(0xFF0C0D0F),
    surface: Color(0xFF17181B),
    sheet: Color(0xFF1D1E22),
    line: Color(0xFF2A2B2F),
    ink: Color(0xFFF2F2F1),
    muted: Color(0xFF9B9DA1),
    faint: Color(0xFF6E7074),
    accent: Color(0xFFF2F2F1),
    accentSoft: Color(0xFF232428),
    accentSoftBorder: Color(0xFF3A3B40),
    accentInk: Color(0xFFF2F2F1),
    onAccent: Color(0xFF0C0D0F),
    avatarPrimary: Color(0xFF4A4C51),
    avatarSecondary: Color(0xFF33353A),
    income: Color(0xFF6BC089),
    danger: Color(0xFFE08070),
  );

  static SkyColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

extension SkyColorsContext on BuildContext {
  /// The Tinta colours for the active theme brightness.
  SkyColors get sky => SkyColors.of(this);
}
