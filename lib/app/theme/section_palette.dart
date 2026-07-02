import 'package:flutter/material.dart';

/// Resolved colours for one dashboard section in the active brightness.
@immutable
class SectionColors {
  const SectionColors({
    required this.tint,
    required this.border,
    required this.strong,
    required this.iconBg,
  });

  /// Soft pastel card background.
  final Color tint;

  /// Card border — one step deeper than [tint].
  final Color border;

  /// The saturated hue: icons, progress fills, emphasis values.
  final Color strong;

  /// Icon-tile background — between [tint] and [strong].
  final Color iconBg;
}

/// A section hue with light + dark variants, resolved by theme brightness.
@immutable
class SectionHue {
  const SectionHue({required this.light, required this.dark});

  final SectionColors light;
  final SectionColors dark;

  SectionColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Per-section identity hues for the Beranda dashboard.
///
/// The "Tinta" chrome stays monochrome; these tints are the deliberate,
/// *meaningful* colour layer: each money domain owns one hue, so the
/// dashboard is scannable by colour. Text on a [SectionColors.tint] card
/// stays ink/muted — only surfaces, icons, and progress carry the hue.
/// Money semantics still win: income green, danger coral override a
/// section hue wherever they apply (e.g. over-budget, income amounts).
abstract final class SectionPalette {
  /// Dompet — denim blue.
  static const dompet = SectionHue(
    light: SectionColors(
      tint: Color(0xFFE9F0F9),
      border: Color(0xFFD6E3F2),
      strong: Color(0xFF3E72B8),
      iconBg: Color(0xFFD9E6F5),
    ),
    dark: SectionColors(
      tint: Color(0xFF1A2434),
      border: Color(0xFF2B3C55),
      strong: Color(0xFF7FA9DC),
      iconBg: Color(0xFF243349),
    ),
  );

  /// Dibagikan untukku — magenta (relational: shared by a partner).
  static const dibagikan = SectionHue(
    light: SectionColors(
      tint: Color(0xFFF9EAF2),
      border: Color(0xFFF0D6E5),
      strong: Color(0xFFB14E86),
      iconBg: Color(0xFFF3DCE9),
    ),
    dark: SectionColors(
      tint: Color(0xFF301E29),
      border: Color(0xFF4C2C3F),
      strong: Color(0xFFDE8FBC),
      iconBg: Color(0xFF402736),
    ),
  );

  /// Anggaran — amber (budget/warning family).
  static const anggaran = SectionHue(
    light: SectionColors(
      tint: Color(0xFFF9F0E1),
      border: Color(0xFFF0E1C6),
      strong: Color(0xFFB87B2E),
      iconBg: Color(0xFFF3E5CC),
    ),
    dark: SectionColors(
      tint: Color(0xFF2F2718),
      border: Color(0xFF4A3C24),
      strong: Color(0xFFE0B05E),
      iconBg: Color(0xFF3E3320),
    ),
  );

  /// Tabungan — green (growth/savings).
  static const tabungan = SectionHue(
    light: SectionColors(
      tint: Color(0xFFE7F3EC),
      border: Color(0xFFD2E7DB),
      strong: Color(0xFF2E8B57),
      iconBg: Color(0xFFD6EBDF),
    ),
    dark: SectionColors(
      tint: Color(0xFF1A2C22),
      border: Color(0xFF294536),
      strong: Color(0xFF6BC089),
      iconBg: Color(0xFF223A2C),
    ),
  );

  /// Cicilan — indigo (fixed obligations).
  static const cicilan = SectionHue(
    light: SectionColors(
      tint: Color(0xFFECEDF9),
      border: Color(0xFFDADCF1),
      strong: Color(0xFF5B62C9),
      iconBg: Color(0xFFDEE0F4),
    ),
    dark: SectionColors(
      tint: Color(0xFF20223A),
      border: Color(0xFF34375D),
      strong: Color(0xFF9BA0E8),
      iconBg: Color(0xFF2B2E4D),
    ),
  );

  /// Langganan — violet (services/subscriptions).
  static const langganan = SectionHue(
    light: SectionColors(
      tint: Color(0xFFF1EBF9),
      border: Color(0xFFE3D8F1),
      strong: Color(0xFF8352C9),
      iconBg: Color(0xFFE7DDF4),
    ),
    dark: SectionColors(
      tint: Color(0xFF29203A),
      border: Color(0xFF40315C),
      strong: Color(0xFFB79BE8),
      iconBg: Color(0xFF362A4C),
    ),
  );

  /// Berulang — teal (cycles/repetition).
  static const berulang = SectionHue(
    light: SectionColors(
      tint: Color(0xFFE4F2F1),
      border: Color(0xFFCEE6E4),
      strong: Color(0xFF178A80),
      iconBg: Color(0xFFD3EAE8),
    ),
    dark: SectionColors(
      tint: Color(0xFF182B29),
      border: Color(0xFF264441),
      strong: Color(0xFF58BFB4),
      iconBg: Color(0xFF203936),
    ),
  );
}
