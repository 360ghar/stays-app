import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      // Override onSurface which affects TextField text color
      onSurface: Colors.black,
    ),
    // Set primary text selection theme
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.black,
      selectionColor: Colors.blue,
      selectionHandleColor: Colors.blue,
    ),
    // Override the default text theme to ensure input text is black
    textTheme: const TextTheme(
      // TextField uses bodyLarge by default in Material 3
      bodyLarge: TextStyle(color: Colors.black),
      // Some TextField widgets might use bodyMedium
      bodyMedium: TextStyle(color: Colors.black),
      // For labels and other text
      titleMedium: TextStyle(color: Colors.black),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: AppTextStyles.h2,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F2F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      // Set hint text color to grey
      hintStyle: TextStyle(color: Colors.grey.shade500),
      // Set label colors
      labelStyle: const TextStyle(color: Colors.black),
      floatingLabelStyle: const TextStyle(color: Colors.black),
      // Set prefix and suffix text colors
      prefixStyle: const TextStyle(color: Colors.black),
      suffixStyle: const TextStyle(color: Colors.black),
      counterStyle: const TextStyle(color: Colors.black),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
}

