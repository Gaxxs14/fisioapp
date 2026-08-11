import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0F766E); // Teal 700
  static const Color secondaryColor = Color(0xFF0D9488); // Teal 600
  static const Color accentColor = Color(0xFF10B981); // Emerald 500
  static const Color errorColor = Color(0xFFEF4444); // Red 500

  // Color del fondo
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color bgDark = Color(0xFF0F172A); // Slate 900

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
