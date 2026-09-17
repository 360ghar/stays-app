import 'package:flutter/material.dart';

import 'package:stays_app/app/ui/theme/app_colors.dart';

/// Calm premium tokens for the rebuild. Photo-first, Airbnb-style.
///
/// Canonical design tokens, together with [AppTheme]
/// (`lib/app/ui/theme/app_theme.dart`): import this file for semantic
/// color/spacing/radius/type use in widgets. [AppColors] stays as the raw
/// palette. The legacy constants in `lib/app/utils/theme.dart` are
/// deprecated; do not use them in new code.
class StayTokens {
  StayTokens._();

  // Brand: one teal accent, calm neutrals. No gradients on CTAs.
  static const Color accent = AppColors.secondary;
  static const Color accentDark = AppColors.secondaryDark;
  static const Color ink = AppColors.textPrimary;
  static const Color inkSecondary = AppColors.textSecondary;
  static const Color inkTertiary = AppColors.textTertiary;
  static const Color paper = AppColors.surface;
  static const Color paperWarm = AppColors.background;
  static const Color line = AppColors.outline;
  static const Color danger = AppColors.error;
  static const Color star = AppColors.starActive;
  static const Color heart = AppColors.favoriteActive;

  // Spacing: 4pt scale.
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // Radius: cards 12, sheets 16, hero 24.
  static const double radiusCard = 12;
  static const double radiusSheet = 16;
  static const double radiusHero = 24;
  static const double radiusPill = 999;

  // Photo ratios.
  static const double ratioCard = 4 / 3;
  static const double ratioHero = 16 / 10;

  // Type scale.
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ink,
    height: 1.25,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.2,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ink,
    height: 1.45,
  );
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: inkSecondary,
    height: 1.45,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: inkSecondary,
    height: 1.35,
  );
  static const TextStyle price = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.3,
  );

  /// Light theme wired to tokens. Dark mode keeps legacy theme for now.
  static ThemeData lightTheme() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          primary: accent,
          surface: paper,
        ).copyWith(
          secondary: accent,
          error: danger,
          surfaceContainerHighest: paperWarm,
          outline: line,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: title,
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusCard),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
