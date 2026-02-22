import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_colors_light.dart';

class AppThemeColors {
  final Color primary;
  final Color primaryDark;
  final Color primaryForeground;
  final Color background;
  final Color foreground;
  final Color surface;
  final Color surfaceLight;
  final Color card;
  final Color secondary;
  final Color secondaryForeground;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color accent;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color borderLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textMuted;
  final Color overlayLight;
  final Color overlayMedium;
  final Color overlayHeavy;
  final Color impulseBlue;
  final Color impulseBlueSoft;

  const AppThemeColors._({
    required this.primary,
    required this.primaryDark,
    required this.primaryForeground,
    required this.background,
    required this.foreground,
    required this.surface,
    required this.surfaceLight,
    required this.card,
    required this.secondary,
    required this.secondaryForeground,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accent,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.borderLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.overlayLight,
    required this.overlayMedium,
    required this.overlayHeavy,
    required this.impulseBlue,
    required this.impulseBlueSoft,
  });

  static const dark = AppThemeColors._(
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryForeground: AppColors.primaryForeground,
    background: AppColors.background,
    foreground: AppColors.foreground,
    surface: AppColors.surface,
    surfaceLight: AppColors.surfaceLight,
    card: AppColors.card,
    secondary: AppColors.secondary,
    secondaryForeground: AppColors.secondaryForeground,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    accent: AppColors.accent,
    muted: AppColors.muted,
    mutedForeground: AppColors.mutedForeground,
    border: AppColors.border,
    borderLight: AppColors.borderLight,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textMuted: AppColors.textMuted,
    overlayLight: AppColors.overlayLight,
    overlayMedium: AppColors.overlayMedium,
    overlayHeavy: AppColors.overlayHeavy,
    impulseBlue: AppColors.impulseBlue,
    impulseBlueSoft: AppColors.impulseBlueSoft,
  );

  static const light = AppThemeColors._(
    primary: AppColorsLight.primary,
    primaryDark: AppColorsLight.primaryDark,
    primaryForeground: AppColorsLight.primaryForeground,
    background: AppColorsLight.background,
    foreground: AppColorsLight.foreground,
    surface: AppColorsLight.surface,
    surfaceLight: AppColorsLight.surfaceLight,
    card: AppColorsLight.card,
    secondary: AppColorsLight.secondary,
    secondaryForeground: AppColorsLight.secondaryForeground,
    success: AppColorsLight.success,
    warning: AppColorsLight.warning,
    error: AppColorsLight.error,
    info: AppColorsLight.info,
    accent: AppColorsLight.accent,
    muted: AppColorsLight.muted,
    mutedForeground: AppColorsLight.mutedForeground,
    border: AppColorsLight.border,
    borderLight: AppColorsLight.borderLight,
    textPrimary: AppColorsLight.textPrimary,
    textSecondary: AppColorsLight.textSecondary,
    textTertiary: AppColorsLight.textTertiary,
    textMuted: AppColorsLight.textMuted,
    overlayLight: AppColorsLight.overlayLight,
    overlayMedium: AppColorsLight.overlayMedium,
    overlayHeavy: AppColorsLight.overlayHeavy,
    impulseBlue: AppColorsLight.impulseBlue,
    impulseBlueSoft: AppColorsLight.impulseBlueSoft,
  );
}

extension ThemeColorsExtension on BuildContext {
  AppThemeColors get colors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppThemeColors.dark
        : AppThemeColors.light;
  }
}
