import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0F766E); // Teal 700
  static const Color secondaryColor = Color(0xFF0D9488); // Teal 600
  static const Color accentColor = Color(0xFF10B981); // Emerald 500
  static const Color errorColor = Color(0xFFEF4444); // Red 500

  // Color del fondo y superficies UI 2.0
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color bgDark = Color(0xFF0A0F1E); // Deep OLED Slate
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF111827); // Slate 900
  static const Color cardDark = Color(0xFF1E293B); // Slate 800
  static const Color amberAlert = Color(0xFFF59E0B); // Amber 500
  static const Color indigoAccent = Color(0xFF6366F1); // Indigo 500
  static const Color skyAccent = Color(0xFF0284C7); // Sky 600

  // Gradientes Modernos
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF0D2137), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Decorador Glassmorphic Reutilizable
  static BoxDecoration glassBox({
    required bool isDark,
    double radius = 16,
    Color? customColor,
    Border? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: customColor ?? (isDark
          ? const Color(0xFF131B2E).withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.90)),
      borderRadius: BorderRadius.circular(radius),
      border: border ?? Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        width: 1,
      ),
      boxShadow: shadows ?? [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: primaryColor,
        primaryContainer: Color(0xFFCCFBF1), // Teal 100
        secondary: secondaryColor,
        secondaryContainer: Color(0xFFE6F4F1),
        tertiary: accentColor,
        error: errorColor,
      ),
      scaffoldBackground: bgLight,
      useMaterial3: true,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnLevel: 8,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorFocusedHasBorder: true,
        cardRadius: 16.0,
        elevatedButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
        textButtonRadius: 12.0,
        elevatedButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSecondarySchemeColor: SchemeColor.onPrimary,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ),
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: primaryColor,
        primaryContainer: Color(0xFF115E59),
        secondary: secondaryColor,
        secondaryContainer: Color(0xFF064E3B),
        tertiary: accentColor,
        error: errorColor,
      ),
      scaffoldBackground: bgDark,
      useMaterial3: true,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnLevel: 15,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 12.0,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorFocusedHasBorder: true,
        cardRadius: 16.0,
        elevatedButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
        textButtonRadius: 12.0,
        elevatedButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSecondarySchemeColor: SchemeColor.onPrimary,
        outlinedButtonOutlineSchemeColor: SchemeColor.primary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }
}
