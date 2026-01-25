import 'package:flutter/material.dart';

/// Premium color palette inspired by top-tier apps like Airbnb, Instagram, and Spotify.
/// Features sophisticated gradients, glassmorphism support, and carefully crafted semantic colors.
class AppColors {
  AppColors._();

  // ===============================================
  // PRIMARY COLORS - Premium Blue gradient system
  // ===============================================

  /// Primary brand color - Vibrant sky blue
  static const Color primary = Color(0xFF3B82F6);

  /// Primary dark - Deep royal blue
  static const Color primaryDark = Color(0xFF1D4ED8);

  /// Primary light - Soft azure
  static const Color primaryLight = Color(0xFF60A5FA);

  /// Primary pale - For subtle backgrounds
  static const Color primaryPale = Color(0xFFDBEAFE);

  /// Content on primary - Always white
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Primary container - Soft blue background
  static const Color primaryContainer = Color(0xFFEFF6FF);

  /// Content on primary container
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  // ===============================================
  // SECONDARY COLORS - Teal accents
  // ===============================================

  /// Secondary - Teal accent for CTAs
  static const Color secondary = Color(0xFF14B8A6);

  /// Secondary dark - Deep teal
  static const Color secondaryDark = Color(0xFF0F766E);

  /// Secondary light - Soft teal
  static const Color secondaryLight = Color(0xFF5EEAD4);

  /// Content on secondary
  static const Color onSecondary = Color(0xFFFFFFFF);

  /// Secondary container
  static const Color secondaryContainer = Color(0xFFF0FDFA);

  // ===============================================
  // TERTIARY COLORS - Purple gradients
  // ===============================================

  /// Tertiary - Elegant violet
  static const Color tertiary = Color(0xFF8B5CF6);

  /// Tertiary dark - Deep violet
  static const Color tertiaryDark = Color(0xFF6D28D9);

  /// Tertiary light - Soft lavender
  static const Color tertiaryLight = Color(0xFFC4B5FD);

  /// Content on tertiary
  static const Color onTertiary = Color(0xFFFFFFFF);

  /// Tertiary container
  static const Color tertiaryContainer = Color(0xFFEDE9FE);

  // ===============================================
  // SURFACE & BACKGROUND COLORS
  // ===============================================

  /// Primary background - Off-white for reduced eye strain
  static const Color background = Color(0xFFFAFBFC);

  /// Background variant - Slightly darker
  static const Color backgroundVariant = Color(0xFFF5F7FA);

  /// Surface - Pure white for cards
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant - Subtle gray
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  /// Surface elevated - For layered content
  static const Color surfaceElevated = Color(0xFFFAFAFA);

  /// Surface dim - For disabled states
  static const Color surfaceDim = Color(0xFFE8EAED);

  // ===============================================
  // DARK MODE COLORS
  // ===============================================

  /// Dark background - Deep navy (not pure black)
  static const Color darkBackground = Color(0xFF0F172A);

  /// Dark surface - Slightly lighter
  static const Color darkSurface = Color(0xFF1E293B);

  /// Dark surface elevated
  static const Color darkSurfaceElevated = Color(0xFF334155);

  // ===============================================
  // TEXT COLORS
  // ===============================================

  /// Primary text - Near black for contrast
  static const Color textPrimary = Color(0xFF0F172A);

  /// Secondary text - Medium gray
  static const Color textSecondary = Color(0xFF64748B);

  /// Tertiary text - Light gray
  static const Color textTertiary = Color(0xFF94A3B8);

  /// Text hint - Very light gray
  static const Color textHint = Color(0xFFCBD5E1);

  /// Text inverse - For dark backgrounds
  static const Color textInverse = Color(0xFFFFFFFF);

  /// Text on surface
  static const Color onSurface = Color(0xFF0F172A);

  /// Text on surface variant
  static const Color onSurfaceVariant = Color(0xFF475569);

  /// Text on background
  static const Color onBackground = Color(0xFF1E293B);

  // ===============================================
  // SEMANTIC COLORS
  // ===============================================

  /// Error - Vibrant red
  static const Color error = Color(0xFFEF4444);

  /// Error dark - Deep red
  static const Color errorDark = Color(0xFFDC2626);

  /// Error container - Light red background
  static const Color errorContainer = Color(0xFFFEE2E2);

  /// Content on error
  static const Color onError = Color(0xFFFFFFFF);

  /// Content on error container
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  /// Success - Vibrant green
  static const Color success = Color(0xFF10B981);

  /// Success dark - Deep green
  static const Color successDark = Color(0xFF059669);

  /// Success container - Light green background
  static const Color successContainer = Color(0xFFD1FAE5);

  /// Content on success
  static const Color onSuccess = Color(0xFFFFFFFF);

  /// Content on success container
  static const Color onSuccessContainer = Color(0xFF064E3B);

  /// Warning - Amber
  static const Color warning = Color(0xFFF59E0B);

  /// Warning dark - Deep amber
  static const Color warningDark = Color(0xFFD97706);

  /// Warning container - Light amber background
  static const Color warningContainer = Color(0xFFFEF3C7);

  /// Content on warning
  static const Color onWarning = Color(0xFF1E293B);

  /// Content on warning container
  static const Color onWarningContainer = Color(0xFF78350F);

  /// Info - Sky blue
  static const Color info = Color(0xFF0EA5E9);

  /// Info dark - Deep sky
  static const Color infoDark = Color(0xFF0284C7);

  /// Info container - Light blue background
  static const Color infoContainer = Color(0xFFE0F2FE);

  /// Content on info
  static const Color onInfo = Color(0xFFFFFFFF);

  /// Content on info container
  static const Color onInfoContainer = Color(0xFF0C4A6E);

  // ===============================================
  // UTILITY COLORS
  // ===============================================

  /// Outline - For borders
  static const Color outline = Color(0xFFE2E8F0);

  /// Outline variant - Lighter borders
  static const Color outlineVariant = Color(0xFFF1F5F9);

  /// Divider - For separators
  static const Color divider = Color(0xFFE2E8F0);

  /// Shadow - For elevation
  static const Color shadow = Color(0xFF0F172A);

  /// Overlay light - White overlay
  static const Color overlayLight = Color(0xFFFFFFFF);

  /// Overlay dark - Dark overlay
  static const Color overlayDark = Color(0xFF1E293B);

  /// Transparent
  static const Color transparent = Color(0x00000000);

  // ===============================================
  // FEATURE-SPECIFIC COLORS
  // ===============================================

  /// Star active - Gold rating
  static const Color starActive = Color(0xFFF59E0B);

  /// Star inactive - Gray placeholder
  static const Color starInactive = Color(0xFFE2E8F0);

  /// Favorite active - Heart red
  static const Color favoriteActive = Color(0xFFEF4444);

  /// Favorite inactive - Heart outline
  static const Color favoriteInactive = Color(0xFF9CA3AF);

  /// Verified badge - Blue checkmark
  static const Color verified = Color(0xFF3B82F6);

  /// Premium/Gold badge
  static const Color premium = Color(0xFFF59E0B);

  /// New badge - Fresh green
  static const Color fresh = Color(0xFF10B981);

  // ===============================================
  // GRADIENT COLORS
  // ===============================================

  /// Primary gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF3B82F6),
    Color(0xFF2563EB),
  ];

  /// Sunset gradient
  static const List<Color> sunsetGradient = [
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  /// Aurora gradient
  static const List<Color> auroraGradient = [
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF14B8A6),
  ];

  /// Ocean gradient
  static const List<Color> oceanGradient = [
    Color(0xFF0EA5E9),
    Color(0xFF2563EB),
  ];

  /// Forest gradient
  static const List<Color> forestGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  // ===============================================
  // GLASSMORPHISM COLORS
  // ===============================================

  /// Glass surface for light mode
  static Color glassLight({double opacity = 0.7}) =>
      const Color(0xFFFFFFFF).withValues(alpha: opacity);

  /// Glass surface for dark mode
  static Color glassDark({double opacity = 0.6}) =>
      const Color(0xFF1E293B).withValues(alpha: opacity);

  /// Glass border for light mode
  static Color glassBorderLight({double opacity = 0.15}) =>
      const Color(0xFF000000).withValues(alpha: opacity);

  /// Glass border for dark mode
  static Color glassBorderDark({double opacity = 0.1}) =>
      const Color(0xFFFFFFFF).withValues(alpha: opacity);

  // ===============================================
  // MATERIAL COLOR SWATCH
  // ===============================================

  /// Material color swatch for primary
  static MaterialColor get primarySwatch =>
      MaterialColor(primary.toARGB32(), <int, Color>{
        50: const Color(0xFFEFF6FF),
        100: const Color(0xFFDBEAFE),
        200: const Color(0xFFBFDBFE),
        300: primaryLight,
        400: const Color(0xFF60A5FA),
        500: primary,
        600: primaryDark,
        700: const Color(0xFF1D4ED8),
        800: const Color(0xFF1E40AF),
        900: const Color(0xFF1E3A8A),
      });
}

/// Premium gradient definitions for common use cases.
class AppGradients {
  AppGradients._();

  /// Primary gradient for buttons and cards
  static const LinearGradient primary = LinearGradient(
    colors: AppColors.primaryGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle vertical gradient for overlays
  static const LinearGradient subtleOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x40000000),
      Color(0x80000000),
    ],
  );

  /// Glassmorphism gradient
  static LinearGradient glass({bool isDark = false}) => LinearGradient(
        colors: [
          isDark
              ? AppColors.glassDark(opacity: 0.3)
              : AppColors.glassLight(opacity: 0.5),
          isDark
              ? AppColors.glassDark(opacity: 0.1)
              : AppColors.glassLight(opacity: 0.2),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Shimmer loading gradient
  static const LinearGradient shimmer = LinearGradient(
    colors: [
      Color(0xFFE5E7EB),
      Color(0xFFF3F4F6),
      Color(0xFFE5E7EB),
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
  );

  /// Card hover gradient
  static const LinearGradient cardHover = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x10FFFFFF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
