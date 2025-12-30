import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        surface: AppColors.surface,
        surfaceContainerHighest: const Color(0xFFE6F0FF),
        outlineVariant: const Color(0xFFD7E4FF),
        onSurface: AppColors.textPrimary,
      );

  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        surface: const Color(0xFF1E293B),
        surfaceContainerHighest: const Color(0xFF273449),
        outlineVariant: const Color(0xFF334155),
        onSurface: Colors.white,
      );

  static ThemeData get lightTheme => _baseTheme(_lightColorScheme);

  static ThemeData get darkTheme => _baseTheme(_darkColorScheme);

  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final baseTypography = ThemeData(
      brightness: colorScheme.brightness,
    ).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      splashColor: colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      textTheme: baseTypography.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      primaryTextTheme: baseTypography.apply(
        bodyColor: colorScheme.onPrimary,
        displayColor: colorScheme.onPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        titleTextStyle: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
        contentTextStyle: baseTypography.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        contentTextStyle: baseTypography.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outlineVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.4);
          }
          return colorScheme.outlineVariant.withValues(alpha: 0.5);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: AppTextStyles.button,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.35),
        selectionHandleColor: colorScheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
        prefixStyle: TextStyle(color: colorScheme.onSurface),
        suffixStyle: TextStyle(color: colorScheme.onSurface),
        counterStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
