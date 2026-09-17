import 'package:flutter/material.dart';

/// LEGACY theme constants. Do not use in new code.
///
/// Canonical theme going forward: design tokens in [StayTokens]
/// (`lib/core/theme/tokens.dart`) + the Material 3 [AppTheme] in
/// `lib/app/ui/theme/app_theme.dart`.
///
/// Deprecated because this class is stale: `errorColor` (and `errorRed`,
/// `successColor`, `warningColor`, `infoColor`) are all blue
/// (`0xFF3B82F6` / `0xFF60A5FA` / `0xFF93C5FD`) instead of semantic
/// red/green/amber, so error states render in primary blue. Kept only until
/// remaining imports migrate to `AppTheme` + `StayTokens`.
@Deprecated(
  'Use StayTokens (lib/core/theme/tokens.dart) + AppTheme '
  '(lib/app/ui/theme/app_theme.dart) instead. This class has the wrong '
  'errorColor (blue, not red).',
)
class AppTheme {
  static const Color primaryColor = Color(0xFF60A5FA);
  static const Color secondaryColor = Color(0xFF93C5FD);
  static const Color accentColor = Color(0xFFBFDBFE);
  static const Color backgroundColor = Color(0xFFF8FBFF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF60A5FA);
  static const Color warningColor = Color(0xFF93C5FD);
  static const Color infoColor = Color(0xFF60A5FA);

  // Additional colors used in the app
  static const Color errorRed = Color(0xFF3B82F6);
  static const Color backgroundWhite = Color(0xFFF8FBFF);

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;

  static const double defaultElevation = 4.0;
  static const double smallElevation = 2.0;
  static const double largeElevation = 8.0;

  static TextStyle get headingStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1E293B),
  );

  static TextStyle get subheadingStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF3B82F6),
  );

  static TextStyle get bodyStyle =>
      const TextStyle(fontSize: 14, color: Color(0xFF334155));

  static TextStyle get captionStyle =>
      const TextStyle(fontSize: 12, color: Color(0xFF64748B));
}
