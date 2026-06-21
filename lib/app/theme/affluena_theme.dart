import 'package:flutter/material.dart';

abstract final class AffluenaColors {
  static const surfaceCanvas = Color(0xFFF7F2EA);
  static const surfaceSoft = Color(0xFFFFFDF8);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const surfaceTintSoft = Color(0xFFECE4D8);
  static const ink = Color(0xFF171714);
  static const inkMuted = Color(0xFF6E665B);
  static const borderSubtle = Color(0xFFE5DCCC);
  static const forest = Color(0xFF315C46);
  static const forestSoft = Color(0xFFDCEADF);
  static const amber = Color(0xFFB4772E);
  static const coral = Color(0xFFB55342);
  static const success = Color(0xFF49764F);

  static const darkCanvas = Color(0xFF151411);
  static const darkSurface = Color(0xFF211F1A);
  static const darkSurfaceElevated = Color(0xFF2A261F);
  static const darkSurfaceTintSoft = Color(0xFF342F26);
  static const darkInk = Color(0xFFF8F3EA);
  static const darkMuted = Color(0xFFBFB6AA);
  static const darkBorderSubtle = Color(0xFF3B352C);
  static const darkForest = Color(0xFF7EB694);
  static const darkForestSoft = Color(0xFF20382D);
  static const darkAmber = Color(0xFFE0A552);
  static const darkCoral = Color(0xFFF09483);
  static const darkSuccess = Color(0xFF88C28F);
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
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.borderSubtle),
        ),
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
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surfaceSoft,
        indicatorColor: colors.forestSoft,
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
