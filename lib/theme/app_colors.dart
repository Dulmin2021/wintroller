import 'package:flutter/material.dart';

/// Dynamic theme tokens with support for Stitch Cyber, Midnight Slate, and Light mode.
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;

  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;

  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;

  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;

  // Status indicators
  final Color statusOnline;
  final Color statusConnecting;
  final Color statusOffline;

  // Module accents
  final Color powerAccent;
  final Color mouseAccent;
  final Color keyboardAccent;
  final Color mediaAccent;
  final Color filesAccent;
  final Color brightnessAccent;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.statusOnline,
    required this.statusConnecting,
    required this.statusOffline,
    required this.powerAccent,
    required this.mouseAccent,
    required this.keyboardAccent,
    required this.mediaAccent,
    required this.filesAccent,
    required this.brightnessAccent,
  });

  /// 1. Stitch Cyber (Proton Remote) Theme Colors
  static const AppThemeColors stitchCyber = AppThemeColors(
    background: Color(0xFF0B1326),
    surface: Color(0xFF0B1326),
    surfaceContainerLowest: Color(0xFF060E20),
    surfaceContainerLow: Color(0xFF131B2E),
    surfaceContainer: Color(0xFF171F33),
    surfaceContainerHigh: Color(0xFF222A3D),
    surfaceContainerHighest: Color(0xFF2D3449),
    primary: Color(0xFFADC6FF),
    onPrimary: Color(0xFF002E6A),
    primaryContainer: Color(0xFF4D8EFF),
    onPrimaryContainer: Color(0xFF00285D),
    secondary: Color(0xFFB7C8E1),
    onSecondary: Color(0xFF213145),
    secondaryContainer: Color(0xFF3A4A5F),
    onSecondaryContainer: Color(0xFFA9BAD3),
    tertiary: Color(0xFF4EDEA3),
    onTertiary: Color(0xFF003824),
    tertiaryContainer: Color(0xFF00A572),
    onTertiaryContainer: Color(0xFF00311F),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    onSurface: Color(0xFFDAE2FD),
    onSurfaceVariant: Color(0xFFC2C6D6),
    outline: Color(0xFF8C909F),
    outlineVariant: Color(0xFF424754),
    statusOnline: Color(0xFF4EDEA3),
    statusConnecting: Color(0xFFFFC107),
    statusOffline: Color(0xFFFF6B6B),
    powerAccent: Color(0xFFFF5252),
    mouseAccent: Color(0xFF448AFF),
    keyboardAccent: Color(0xFF7C4DFF),
    mediaAccent: Color(0xFFFF9800),
    filesAccent: Color(0xFF00E676),
    brightnessAccent: Color(0xFFFFD600),
  );

  /// 2. Midnight Slate (Charcoal & Sky Cyan) Theme Colors
  static const AppThemeColors midnight = AppThemeColors(
    background: Color(0xFF0F172A),
    surface: Color(0xFF0F172A),
    surfaceContainerLowest: Color(0xFF090D16),
    surfaceContainerLow: Color(0xFF141D2E),
    surfaceContainer: Color(0xFF1E293B),
    surfaceContainerHigh: Color(0xFF334155),
    surfaceContainerHighest: Color(0xFF475569),
    primary: Color(0xFF38BDF8),
    onPrimary: Color(0xFF082F49),
    primaryContainer: Color(0xFF0284C7),
    onPrimaryContainer: Color(0xFFE0F2FE),
    secondary: Color(0xFF94A3B8),
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: Color(0xFF334155),
    onSecondaryContainer: Color(0xFFCBD5E1),
    tertiary: Color(0xFF34D399),
    onTertiary: Color(0xFF064E3B),
    tertiaryContainer: Color(0xFF059669),
    onTertiaryContainer: Color(0xFFECFDF5),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFFDC2626),
    onErrorContainer: Color(0xFFFEF2F2),
    onSurface: Color(0xFFF8FAFC),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFF334155),
    statusOnline: Color(0xFF34D399),
    statusConnecting: Color(0xFFFBBF24),
    statusOffline: Color(0xFFEF4444),
    powerAccent: Color(0xFFF87171),
    mouseAccent: Color(0xFF38BDF8),
    keyboardAccent: Color(0xFF818CF8),
    mediaAccent: Color(0xFFF59E0B),
    filesAccent: Color(0xFF10B981),
    brightnessAccent: Color(0xFFFBBF24),
  );

  /// 3. Clean Light Mode Colors
  static const AppThemeColors light = AppThemeColors(
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF1F5F9),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHigh: Color(0xFFF1F5F9),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    primary: Color(0xFF0284C7),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF0284C7),
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF475569),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE2E8F0),
    onSecondaryContainer: Color(0xFF1E293B),
    tertiary: Color(0xFF059669),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFF10B981),
    onTertiaryContainer: Colors.white,
    error: Color(0xFFDC2626),
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    onSurface: Color(0xFF0F172A),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFE2E8F0),
    statusOnline: Color(0xFF10B981),
    statusConnecting: Color(0xFFD97706),
    statusOffline: Color(0xFFDC2626),
    powerAccent: Color(0xFFDC2626),
    mouseAccent: Color(0xFF0284C7),
    keyboardAccent: Color(0xFF6366F1),
    mediaAccent: Color(0xFFD97706),
    filesAccent: Color(0xFF059669),
    brightnessAccent: Color(0xFFD97706),
  );

  @override
  ThemeExtension<AppThemeColors> copyWith({
    Color? background,
    Color? surface,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? statusOnline,
    Color? statusConnecting,
    Color? statusOffline,
    Color? powerAccent,
    Color? mouseAccent,
    Color? keyboardAccent,
    Color? mediaAccent,
    Color? filesAccent,
    Color? brightnessAccent,
  }) {
    return AppThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainerLowest: surfaceContainerLowest ?? this.surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest ?? this.surfaceContainerHighest,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      errorContainer: errorContainer ?? this.errorContainer,
      onErrorContainer: onErrorContainer ?? this.onErrorContainer,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      statusOnline: statusOnline ?? this.statusOnline,
      statusConnecting: statusConnecting ?? this.statusConnecting,
      statusOffline: statusOffline ?? this.statusOffline,
      powerAccent: powerAccent ?? this.powerAccent,
      mouseAccent: mouseAccent ?? this.mouseAccent,
      keyboardAccent: keyboardAccent ?? this.keyboardAccent,
      mediaAccent: mediaAccent ?? this.mediaAccent,
      filesAccent: filesAccent ?? this.filesAccent,
      brightnessAccent: brightnessAccent ?? this.brightnessAccent,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    covariant ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainerLowest: Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow: Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest: Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer: Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer: Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer: Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      tertiaryContainer: Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onTertiaryContainer: Color.lerp(onTertiaryContainer, other.onTertiaryContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer: Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      statusOnline: Color.lerp(statusOnline, other.statusOnline, t)!,
      statusConnecting: Color.lerp(statusConnecting, other.statusConnecting, t)!,
      statusOffline: Color.lerp(statusOffline, other.statusOffline, t)!,
      powerAccent: Color.lerp(powerAccent, other.powerAccent, t)!,
      mouseAccent: Color.lerp(mouseAccent, other.mouseAccent, t)!,
      keyboardAccent: Color.lerp(keyboardAccent, other.keyboardAccent, t)!,
      mediaAccent: Color.lerp(mediaAccent, other.mediaAccent, t)!,
      filesAccent: Color.lerp(filesAccent, other.filesAccent, t)!,
      brightnessAccent: Color.lerp(brightnessAccent, other.brightnessAccent, t)!,
    );
  }
}

/// Fallback constant values for backward compatibility and static contexts
class AppColors {
  AppColors._();

  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ?? AppThemeColors.stitchCyber;
  }

  static const Color background = Color(0xFF0B1326);
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHigh = Color(0xFF222A3D);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);
  static const Color surfaceContainerLowest = Color(0xFF060E20);
  static const Color surfaceContainerLow = Color(0xFF131B2E);

  static const Color primary = Color(0xFFADC6FF);
  static const Color onPrimary = Color(0xFF002E6A);
  static const Color primaryContainer = Color(0xFF4D8EFF);
  static const Color onPrimaryContainer = Color(0xFF00285D);

  static const Color secondary = Color(0xFFB7C8E1);
  static const Color onSecondary = Color(0xFF213145);
  static const Color secondaryContainer = Color(0xFF3A4A5F);
  static const Color onSecondaryContainer = Color(0xFFA9BAD3);

  static const Color tertiary = Color(0xFF4EDEA3);
  static const Color onTertiary = Color(0xFF003824);
  static const Color tertiaryContainer = Color(0xFF00A572);
  static const Color onTertiaryContainer = Color(0xFF00311F);

  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFC2C6D6);
  static const Color outline = Color(0xFF8C909F);
  static const Color outlineVariant = Color(0xFF424754);

  static const Color statusOnline = Color(0xFF4EDEA3);
  static const Color statusConnecting = Color(0xFFFFC107);
  static const Color statusOffline = Color(0xFFFF6B6B);

  static const Color powerAccent = Color(0xFFFF5252);
  static const Color mouseAccent = Color(0xFF448AFF);
  static const Color keyboardAccent = Color(0xFF7C4DFF);
  static const Color mediaAccent = Color(0xFFFF9800);
  static const Color filesAccent = Color(0xFF00E676);
  static const Color brightnessAccent = Color(0xFFFFD600);
}
