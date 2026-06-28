import 'package:flutter/material.dart';

/// Sky & Denim — the redesign palette (Tahap 1 foundation).
///
/// Introduced additively: the redesign primitives reference these tokens
/// directly so the new surfaces can be built and reviewed without touching the
/// live [AffluenaColors] / [AffluenaSemanticColors] theme that existing screens
/// still use. A later stage migrates the rest of the app onto this palette.
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
