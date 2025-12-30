import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);

  static const Color secondary = Color(0xFF93C5FD);
  static const Color secondaryDark = Color(0xFF60A5FA);
  static const Color secondaryLight = Color(0xFFBFDBFE);
  static const Color onSecondary = Color(0xFF1E3A8A);
  static const Color secondaryContainer = Color(0xFFE0F2FE);
  static const Color onSecondaryContainer = Color(0xFF1E40AF);

  static const Color tertiary = Color(0xFF818CF8);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE0E7FF);
  static const Color onTertiaryContainer = Color(0xFF3730A3);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color onSurfaceVariant = Color(0xFF475569);

  static const Color background = Color(0xFFF8FBFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0);
  static const Color surfaceContainerHigh = Color(0xFFEEF2F6);
  static const Color surfaceContainer = Color(0xFFF8FAFC);
  static const Color surfaceContainerLow = Color(0xFFFDFDFE);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1E293B);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onSuccessContainer = Color(0xFF14532D);

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFF1E293B);
  static const Color onWarningContainer = Color(0xFF78350F);

  static const Color info = Color(0xFF0891B2);
  static const Color infoContainer = Color(0xFFCCEEF3);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color onInfoContainer = Color(0xFF164E63);

  static const Color outline = Color(0xFFCBD5E1);
  static const Color outlineVariant = Color(0xFFE2E8F0);

  static const Color divider = Color(0xFFE2E8F0);

  static const Color shadow = Color(0xFF1E293B);

  static const Color overlayLight = Color(0xFFFFFFFF);
  static const Color overlayDark = Color(0xFF1E293B);

  static const Color starActive = Color(0xFFFBBF24);
  static const Color starInactive = Color(0xFFE2E8F0);

  static const Color favoriteActive = Color(0xFFEF4444);
  static const Color favoriteInactive = Color(0xFF94A3B8);

  static const Color transparent = Color(0x00000000);

  // Use toARGB32() instead of deprecated .value for explicit color conversion
  static MaterialColor get primarySwatch =>
      MaterialColor(primary.toARGB32(), <int, Color>{
        50: primaryLight,
        100: primaryLight,
        200: primary,
        300: primary,
        400: primaryDark,
        500: primary,
        600: primaryDark,
        700: primaryDark,
        800: primaryDark,
        900: primaryDark,
      });
}
