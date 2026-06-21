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
  static const darkInk = Color(0xFFF8F3EA);
  static const darkMuted = Color(0xFFBFB6AA);
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
    return _theme(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AffluenaColors.forest,
            brightness: Brightness.light,
            surface: AffluenaColors.surfaceSoft,
          ).copyWith(
            primary: AffluenaColors.forest,
            onPrimary: AffluenaColors.surfaceElevated,
            secondary: AffluenaColors.amber,
            surface: AffluenaColors.surfaceSoft,
            onSurface: AffluenaColors.ink,
            error: AffluenaColors.coral,
          ),
      scaffoldBackground: AffluenaColors.surfaceCanvas,
      cardColor: AffluenaColors.surfaceSoft,
      textColor: AffluenaColors.ink,
      mutedColor: AffluenaColors.inkMuted,
      borderColor: AffluenaColors.borderSubtle,
    );
  }

  static ThemeData get dark {
    return _theme(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AffluenaColors.forest,
            brightness: Brightness.dark,
            surface: AffluenaColors.darkSurface,
          ).copyWith(
            primary: const Color(0xFF7EB694),
            onPrimary: AffluenaColors.darkCanvas,
            secondary: const Color(0xFFE0A552),
            surface: AffluenaColors.darkSurface,
            onSurface: AffluenaColors.darkInk,
            error: const Color(0xFFF09483),
          ),
      scaffoldBackground: AffluenaColors.darkCanvas,
      cardColor: AffluenaColors.darkSurface,
      textColor: AffluenaColors.darkInk,
      mutedColor: AffluenaColors.darkMuted,
      borderColor: const Color(0xFF3B352C),
    );
  }

  static ThemeData _theme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardColor,
      fontFamily: null,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AffluenaColors.surfaceTintSoft,
        selectedColor: AffluenaColors.forestSoft,
        side: BorderSide(color: borderColor),
        labelStyle: TextStyle(
          color: textColor,
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
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: AffluenaColors.forestSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? colorScheme.primary : mutedColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(
          color: textColor,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.12,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.18,
        ),
        titleLarge: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        bodyMedium: TextStyle(color: textColor, fontSize: 14, height: 1.45),
        bodySmall: TextStyle(color: mutedColor, fontSize: 13, height: 1.4),
        labelMedium: TextStyle(
          color: mutedColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
