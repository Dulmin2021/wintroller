import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  /// 1. Alienware Sci-Fi Cyberpunk HUD Theme (Alien Remote Interface)
  static ThemeData get alienHudTheme {
    final colors = AppThemeColors.alienHud;
    final baseTextTheme = ThemeData.dark(useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.rajdhaniTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.onPrimaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.onSecondaryContainer,
        tertiary: colors.tertiary,
        onTertiary: colors.onTertiary,
        tertiaryContainer: colors.tertiaryContainer,
        onTertiaryContainer: colors.onTertiaryContainer,
        error: colors.error,
        onError: colors.onError,
        errorContainer: colors.errorContainer,
        onErrorContainer: colors.onErrorContainer,
        surface: colors.surface,
        onSurface: colors.onSurface,
        surfaceContainerLowest: colors.surfaceContainerLowest,
        surfaceContainerLow: colors.surfaceContainerLow,
        surfaceContainer: colors.surfaceContainer,
        surfaceContainerHigh: colors.surfaceContainerHigh,
        surfaceContainerHighest: colors.surfaceContainerHighest,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
      ),
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: colors.primary,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.primary.withOpacity(0.4), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.outlineVariant,
        thumbColor: colors.primary,
        trackHeight: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.primary.withOpacity(0.5), width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  /// 2. Stitch Cyber (Proton Remote) Theme - Extracted from Stitch UI Design System
  static ThemeData get stitchCyberTheme {
    final colors = AppThemeColors.stitchCyber;
    final baseTextTheme = ThemeData.dark(useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.onPrimaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.onSecondaryContainer,
        tertiary: colors.tertiary,
        onTertiary: colors.onTertiary,
        tertiaryContainer: colors.tertiaryContainer,
        onTertiaryContainer: colors.onTertiaryContainer,
        error: colors.error,
        onError: colors.onError,
        errorContainer: colors.errorContainer,
        onErrorContainer: colors.onErrorContainer,
        surface: colors.surface,
        onSurface: colors.onSurface,
        surfaceContainerLowest: colors.surfaceContainerLowest,
        surfaceContainerLow: colors.surfaceContainerLow,
        surfaceContainer: colors.surfaceContainer,
        surfaceContainerHigh: colors.surfaceContainerHigh,
        surfaceContainerHighest: colors.surfaceContainerHighest,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
      ),
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primaryContainer,
        inactiveTrackColor: colors.surfaceContainerHighest,
        thumbColor: colors.primary,
        trackHeight: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant, width: 0.8),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  /// 3. Midnight Slate (Charcoal & Sky Cyan) Theme
  static ThemeData get midnightTheme {
    final colors = AppThemeColors.midnight;
    final baseTextTheme = ThemeData.dark(useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.onPrimaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.onSecondaryContainer,
        tertiary: colors.tertiary,
        onTertiary: colors.onTertiary,
        tertiaryContainer: colors.tertiaryContainer,
        onTertiaryContainer: colors.onTertiaryContainer,
        error: colors.error,
        onError: colors.onError,
        errorContainer: colors.errorContainer,
        onErrorContainer: colors.onErrorContainer,
        surface: colors.surface,
        onSurface: colors.onSurface,
        surfaceContainerLowest: colors.surfaceContainerLowest,
        surfaceContainerLow: colors.surfaceContainerLow,
        surfaceContainer: colors.surfaceContainer,
        surfaceContainerHigh: colors.surfaceContainerHigh,
        surfaceContainerHighest: colors.surfaceContainerHighest,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
      ),
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant, width: 0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryContainer,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primaryContainer,
        inactiveTrackColor: colors.surfaceContainerHighest,
        thumbColor: colors.primary,
        trackHeight: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant, width: 0.8),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  /// 4. Clean Light Theme
  static ThemeData get lightTheme {
    final colors = AppThemeColors.light;
    final baseTextTheme = ThemeData.light(useMaterial3: true).textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.onPrimaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.onSecondaryContainer,
        tertiary: colors.tertiary,
        onTertiary: colors.onTertiary,
        tertiaryContainer: colors.tertiaryContainer,
        onTertiaryContainer: colors.onTertiaryContainer,
        error: colors.error,
        onError: colors.onError,
        errorContainer: colors.errorContainer,
        onErrorContainer: colors.onErrorContainer,
        surface: colors.surface,
        onSurface: colors.onSurface,
        surfaceContainerLowest: colors.surfaceContainerLowest,
        surfaceContainerLow: colors.surfaceContainerLow,
        surfaceContainer: colors.surfaceContainer,
        surfaceContainerHigh: colors.surfaceContainerHigh,
        surfaceContainerHighest: colors.surfaceContainerHighest,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
      ),
      textTheme: textTheme,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  static ThemeData get darkTheme => alienHudTheme;
}
