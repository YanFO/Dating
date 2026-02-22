import 'package:flutter/material.dart';

/// App color tokens - Dating Lens dark theme
abstract final class AppColors {
  // Primary colors (Pink accent from UI design)
  static const Color primary = Color(0xFFFF66A1);
  static const Color primaryDark = Color(0xFFD83B7D);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Background colors
  static const Color background = Color(0xFF09090B);
  static const Color foreground = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFF141417);
  static const Color surfaceLight = Color(0xFF18181B);
  static const Color card = Color(0xFF141417);

  // Secondary colors
  static const Color secondary = Color(0xFF18181B);
  static const Color secondaryForeground = Color(0xFFFAFAFA);

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color successBackground = Color(0x1A10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBackground = Color(0x1AF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBackground = Color(0x1ADC2626);
  static const Color info = Color(0xFF3B82F6);

  // Accent colors
  static const Color accent = Color(0xFFFF66A1);
  static const Color accentForeground = Color(0xFFFFFFFF);

  // Muted/Border colors
  static const Color muted = Color(0xFF27272A);
  static const Color mutedForeground = Color(0xFFA1A1AA);
  static const Color border = Color(0x0DFFFFFF); // white/5
  static const Color borderLight = Color(0x1AFFFFFF); // white/10

  // Text colors
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA); // zinc-400
  static const Color textTertiary = Color(0xFF71717A); // zinc-500
  static const Color textMuted = Color(0xFF52525B); // zinc-600

  // Overlay colors
  static const Color overlayLight = Color(0x0DFFFFFF); // white/5
  static const Color overlayMedium = Color(0x1AFFFFFF); // white/10
  static const Color overlayHeavy = Color(0x33FFFFFF); // white/20

  // Impulse control (blue theme)
  static const Color impulseBlue = Color(0xFF3B82F6);
  static const Color impulseBlueSoft = Color(0x1A3B82F6);

  // Border radius values
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radius2Xl = 24.0;
  static const double radius3Xl = 30.0;
}
