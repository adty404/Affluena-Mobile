import 'package:flutter/material.dart';

import 'sky_palette.dart';

/// The app-wide semantic palette. As of the redesign, these resolve to the
/// "Sky & Denim" language ([SkyPalette]) so every themed feature screen matches
/// the redesign surfaces — the old warm-paper palette is fully retired. The
/// token names are kept (e.g. `forest` now holds the denim accent) so the wide
/// surface of existing `context.affluenaColors.*` call sites is untouched.
abstract final class AffluenaColors {
  // Light — Sky & Denim.
  static const surfaceCanvas = SkyPalette.ground;
  static const surfaceSoft = SkyPalette.surface;
  static const surfaceElevated = SkyPalette.surface;
  static const surfaceTintSoft = SkyPalette.sheet;
  static const ink = SkyPalette.ink;
  static const inkMuted = SkyPalette.muted;
  static const borderSubtle = SkyPalette.line;
  static const forest = SkyPalette.accent;
  static const forestSoft = SkyPalette.accentSoft;
  static const amber = Color(0xFFB87B2E);
  static const coral = SkyPalette.danger;
  static const success = SkyPalette.income;

  // Dark — a cool, Sky-flavoured dark (replaces the old warm dark).
  static const darkCanvas = Color(0xFF0F1822);
  static const darkSurface = Color(0xFF16212E);
  static const darkSurfaceElevated = Color(0xFF1C2A39);
  static const darkSurfaceTintSoft = Color(0xFF22323F);
  static const darkInk = Color(0xFFE8EEF4);
  static const darkMuted = Color(0xFF9FB0C0);
  static const darkBorderSubtle = Color(0xFF2A3A48);
  static const darkForest = Color(0xFF6BA0D8);
  static const darkForestSoft = Color(0xFF1E3147);
  static const darkAmber = Color(0xFFE0B05E);
  static const darkCoral = Color(0xFFE08070);
  static const darkSuccess = Color(0xFF6BC089);
}

@immutable
class AffluenaSemanticColors extends ThemeExtension<AffluenaSemanticColors> {
  const AffluenaSemanticColors({
    required this.surfaceCanvas,
    required this.surfaceSoft,
    required this.surfaceElevated,
    required this.surfaceTintSoft,
    required this.ink,
    required this.inkMuted,
    required this.borderSubtle,
    required this.forest,
    required this.forestSoft,
    required this.amber,
    required this.coral,
    required this.success,
  });

  final Color surfaceCanvas;
  final Color surfaceSoft;
  final Color surfaceElevated;
  final Color surfaceTintSoft;
  final Color ink;
  final Color inkMuted;
  final Color borderSubtle;
  final Color forest;
  final Color forestSoft;
  final Color amber;
  final Color coral;
  final Color success;

  static const light = AffluenaSemanticColors(
    surfaceCanvas: AffluenaColors.surfaceCanvas,
    surfaceSoft: AffluenaColors.surfaceSoft,
    surfaceElevated: AffluenaColors.surfaceElevated,
    surfaceTintSoft: AffluenaColors.surfaceTintSoft,
    ink: AffluenaColors.ink,
    inkMuted: AffluenaColors.inkMuted,
    borderSubtle: AffluenaColors.borderSubtle,
    forest: AffluenaColors.forest,
    forestSoft: AffluenaColors.forestSoft,
    amber: AffluenaColors.amber,
    coral: AffluenaColors.coral,
    success: AffluenaColors.success,
  );

  static const dark = AffluenaSemanticColors(
    surfaceCanvas: AffluenaColors.darkCanvas,
    surfaceSoft: AffluenaColors.darkSurface,
    surfaceElevated: AffluenaColors.darkSurfaceElevated,
    surfaceTintSoft: AffluenaColors.darkSurfaceTintSoft,
    ink: AffluenaColors.darkInk,
    inkMuted: AffluenaColors.darkMuted,
    borderSubtle: AffluenaColors.darkBorderSubtle,
    forest: AffluenaColors.darkForest,
    forestSoft: AffluenaColors.darkForestSoft,
    amber: AffluenaColors.darkAmber,
    coral: AffluenaColors.darkCoral,
    success: AffluenaColors.darkSuccess,
  );

  @override
  AffluenaSemanticColors copyWith({
    Color? surfaceCanvas,
    Color? surfaceSoft,
    Color? surfaceElevated,
    Color? surfaceTintSoft,
    Color? ink,
    Color? inkMuted,
    Color? borderSubtle,
    Color? forest,
    Color? forestSoft,
    Color? amber,
    Color? coral,
    Color? success,
  }) {
    return AffluenaSemanticColors(
      surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceTintSoft: surfaceTintSoft ?? this.surfaceTintSoft,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      forest: forest ?? this.forest,
      forestSoft: forestSoft ?? this.forestSoft,
      amber: amber ?? this.amber,
      coral: coral ?? this.coral,
      success: success ?? this.success,
    );
  }

  @override
  AffluenaSemanticColors lerp(
    ThemeExtension<AffluenaSemanticColors>? other,
    double t,
  ) {
    if (other is! AffluenaSemanticColors) return this;
    return AffluenaSemanticColors(
      surfaceCanvas: Color.lerp(surfaceCanvas, other.surfaceCanvas, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      surfaceTintSoft: Color.lerp(surfaceTintSoft, other.surfaceTintSoft, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      forest: Color.lerp(forest, other.forest, t)!,
      forestSoft: Color.lerp(forestSoft, other.forestSoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}

extension AffluenaThemeContext on BuildContext {
  AffluenaSemanticColors get affluenaColors {
    final theme = Theme.of(this);
    return theme.extension<AffluenaSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AffluenaSemanticColors.dark
            : AffluenaSemanticColors.light);
  }
}

abstract final class AffluenaSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
}

abstract final class AffluenaInsets {
  /// Standard scroll-body padding used by full-screen ListViews.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    AffluenaSpacing.space5,
    AffluenaSpacing.space4,
    AffluenaSpacing.space5,
    AffluenaSpacing.space8,
  );
}

abstract final class AffluenaRadii {
  static const double md = 14;
  static const double lg = 16;
  static const double control = 18;
  static const double card = 20;
  static const double sheet = 24;
  static const double pill = 999;
}

abstract final class AffluenaTheme {
  static ThemeData get light {
    const colors = AffluenaSemanticColors.light;
    return _theme(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: colors.forest,
            brightness: Brightness.light,
            surface: colors.surfaceSoft,
          ).copyWith(
            primary: colors.forest,
            onPrimary: colors.surfaceElevated,
            secondary: colors.amber,
            surface: colors.surfaceSoft,
            onSurface: colors.ink,
            error: colors.coral,
          ),
      colors: colors,
    );
  }

  static ThemeData get dark {
    const colors = AffluenaSemanticColors.dark;
    return _theme(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: colors.forest,
            brightness: Brightness.dark,
            surface: colors.surfaceSoft,
          ).copyWith(
            primary: colors.forest,
            onPrimary: colors.surfaceCanvas,
            secondary: colors.amber,
            surface: colors.surfaceSoft,
            onSurface: colors.ink,
            error: colors.coral,
          ),
      colors: colors,
    );
  }

  static ThemeData _theme({
    required ColorScheme colorScheme,
    required AffluenaSemanticColors colors,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.surfaceCanvas,
      cardColor: colors.surfaceSoft,
      fontFamily: null,
    );

    return base.copyWith(
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surfaceCanvas,
        foregroundColor: colors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceSoft,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AffluenaRadii.card),
          side: BorderSide(color: colors.borderSubtle),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surfaceTintSoft,
        selectedColor: colors.forestSoft,
        side: BorderSide(color: colors.borderSubtle),
        labelStyle: TextStyle(
          color: colors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AffluenaRadii.control),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        modalBackgroundColor: colors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: colors.ink.withAlpha(24),
        elevation: 8,
        modalElevation: 12,
        showDragHandle: true,
        dragHandleColor: colors.borderSubtle,
        dragHandleSize: const Size(44, 4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AffluenaRadii.sheet),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AffluenaSpacing.space4,
          vertical: AffluenaSpacing.space3,
        ),
        hintStyle: TextStyle(color: colors.inkMuted),
        prefixIconColor: colors.inkMuted,
        suffixIconColor: colors.inkMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AffluenaRadii.control),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AffluenaRadii.control),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AffluenaRadii.control),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.forest,
        textColor: colors.ink,
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 36,
        horizontalTitleGap: AffluenaSpacing.space3,
        titleTextStyle: TextStyle(
          color: colors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        subtitleTextStyle: TextStyle(
          color: colors.inkMuted,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colors.surfaceSoft,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.forestSoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AffluenaRadii.lg),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? colorScheme.primary : colors.inkMuted,
            size: isSelected ? 25 : 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? colorScheme.primary : colors.inkMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(
          color: colors.ink,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.12,
        ),
        headlineMedium: TextStyle(
          color: colors.ink,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
        titleLarge: TextStyle(
          color: colors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleMedium: TextStyle(
          color: colors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          color: colors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        bodyMedium: TextStyle(color: colors.ink, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: colors.inkMuted, fontSize: 13, height: 1.4),
        labelMedium: TextStyle(
          color: colors.inkMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
