import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Premium theme configuration inspired by top-tier apps.
/// Features sophisticated shadows, smooth animations, and glassmorphism effects.
class AppTheme {
  /// Light color scheme with premium shadows and surfaces
  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        surfaceContainerHigh: const Color(0xFFF1F5F9),
        surfaceContainer: const Color(0xFFF8FAFC),
        outlineVariant: AppColors.outlineVariant,
        onSurface: AppColors.textPrimary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
      );

  /// Dark color scheme with deep navy tones
  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceElevated,
        surfaceContainerHigh: const Color(0xFF334155),
        surfaceContainer: const Color(0xFF1E293B),
        outlineVariant: const Color(0xFF334155),
        onSurface: Colors.white,
        primary: AppColors.primaryLight,
        onPrimary: AppColors.onPrimary,
        primaryContainer: const Color(0xFF1E3A8A),
        onPrimaryContainer: const Color(0xFFDBEAFE),
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.onSecondary,
        tertiary: AppColors.tertiaryLight,
        onTertiary: AppColors.onTertiary,
        error: AppColors.error,
        onError: AppColors.onError,
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
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      canvasColor: colorScheme.surface,
      splashFactory: InkRipple.splashFactory,
      splashColor: colorScheme.primary.withValues(alpha: 0.12),
      highlightColor: colorScheme.primary.withValues(alpha: 0.08),
      hoverColor: colorScheme.primary.withValues(alpha: 0.04),
      textTheme: baseTypography.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      primaryTextTheme: baseTypography.apply(
        bodyColor: colorScheme.onPrimary,
        displayColor: colorScheme.onPrimary,
      ),
      // Premium AppBar with glass effect
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTextStyles.h2.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      // Premium Card theme with smooth shadows
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark
              ? BorderSide.none
              : BorderSide(
                  color: AppColors.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
        ),
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.06),
      ),
      // Premium Dialog with rounded corners
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 24,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.15),
        titleTextStyle: AppTextStyles.h2.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: baseTypography.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          height: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
      ),
      // Premium bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.1),
        modalElevation: 16,
        dragHandleColor: colorScheme.onSurface.withValues(alpha: 0.4),
        dragHandleSize: const Size(40, 4),
      ),
      // Premium divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      // Premium snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 12,
        contentTextStyle: baseTypography.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actionBackgroundColor: colorScheme.primary,
        actionTextColor: colorScheme.onPrimary,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      // Premium bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.5),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: isDark ? 0 : 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
      // Premium switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outlineVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          return colorScheme.outlineVariant.withValues(alpha: 0.4);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      // Premium checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      // Premium radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
      ),
      // Premium elevated button with gradient support
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          elevation: isDark ? 0 : 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      // Premium filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      // Premium outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          textStyle: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      // Premium text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: colorScheme.primary,
          textStyle: AppTextStyles.button.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      // Premium icon button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          hoverColor: colorScheme.primary.withValues(alpha: 0.08),
          focusColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(12),
        ),
      ),
      // Premium floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: isDark ? 2 : 4,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        splashColor: colorScheme.onPrimary.withValues(alpha: 0.3),
        iconSize: 24,
      ),
      // Premium chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        brightness: colorScheme.brightness,
        labelStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide.none,
        secondaryLabelStyle: baseTextStyle(colorScheme.onPrimary).copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.primary,
      ),
      // Premium text selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: colorScheme.primary,
      ),
      // Premium input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : AppColors.surfaceVariant.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixStyle: TextStyle(
          color: colorScheme.onSurface,
        ),
        suffixStyle: TextStyle(
          color: colorScheme.onSurface,
        ),
        counterStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        errorStyle: TextStyle(
          color: colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
        focusColor: colorScheme.primary.withValues(alpha: 0.1),
        hoverColor: colorScheme.primary.withValues(alpha: 0.04),
      ),
      // Premium slider
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: baseTextStyle(colorScheme.onPrimary),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      // Premium progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        refreshBackgroundColor: colorScheme.surface,
      ),
      // Premium scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        trackVisibility: WidgetStateProperty.all(false),
        crossAxisMargin: 4,
        radius: const Radius.circular(3),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return colorScheme.onSurface.withValues(alpha: 0.6);
          }
          return colorScheme.onSurface.withValues(alpha: 0.3);
        }),
      ),
      // Premium tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: baseTextStyle(Colors.white).copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 3),
      ),
      // Premium badge
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
        smallSize: 8,
        largeSize: 20,
        textStyle: baseTextStyle(colorScheme.onError).copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.topRight,
      ),
      // Premium list tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        iconColor: colorScheme.onSurface.withValues(alpha: 0.6),
        selectedColor: colorScheme.primary,
        titleTextStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        subtitleTextStyle: baseTextStyle(colorScheme.onSurfaceVariant).copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),
      // Premium navigation rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        elevation: isDark ? 0 : 4,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          size: 24,
        ),
        selectedLabelTextStyle: baseTextStyle(colorScheme.primary).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: baseTextStyle(
          colorScheme.onSurface.withValues(alpha: 0.6),
        ).copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        labelType: NavigationRailLabelType.all,
      ),
      // Premium tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
        splashFactory: InkRipple.splashFactory,
        overlayColor: WidgetStateProperty.all(
          colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
      // Premium bottom app bar
      bottomAppBarTheme: BottomAppBarThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 8,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: const CircularNotchedRectangle(),
      ),
      // Premium navigation drawer
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surface,
        elevation: isDark ? 0 : 16,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.1),
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.6),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        tileHeight: 56,
      ),
      // Premium search bar
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(
          isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : AppColors.surfaceVariant.withValues(alpha: 0.6),
        ),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide.none,
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textStyle: WidgetStateProperty.all(
          baseTextStyle(colorScheme.onSurface).copyWith(fontSize: 16),
        ),
        hintStyle: WidgetStateProperty.all(
          baseTextStyle(colorScheme.onSurface.withValues(alpha: 0.5))
              .copyWith(fontSize: 16),
        ),
      ),
      // Premium search view
      searchViewTheme: SearchViewThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        headerTextStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        headerHintStyle: baseTextStyle(
          colorScheme.onSurface.withValues(alpha: 0.5),
        ).copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 20,
        ),
      ),
      // Premium menu
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(colorScheme.surface),
          elevation: WidgetStateProperty.all(8),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          shadowColor: WidgetStateProperty.all(
            isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      // Premium popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      // Premium DataTable
      dataTableTheme: DataTableThemeData(
        headingTextStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dataTextStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        dataRowColor: WidgetStateProperty.all(Colors.transparent),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
      ),
      // Premium time picker
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        hourMinuteColor: colorScheme.onSurface.withValues(alpha: 0.9),
        hourMinuteTextColor: colorScheme.primary,
        dialHandColor: colorScheme.primary,
        dialBackgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        entryModeIconColor: colorScheme.primary,
      ),
      // Premium date picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colorScheme.surface,
        headerBackgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        headerForegroundColor: colorScheme.primary,
        todayForegroundColor: WidgetStateProperty.all(colorScheme.primary),
        todayBackgroundColor: WidgetStateProperty.all(
          colorScheme.primaryContainer.withValues(alpha: 0.5),
        ),
        dayForegroundColor: WidgetStateProperty.all(colorScheme.onSurface),
        dayStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w500,
        ),
        yearForegroundColor: WidgetStateProperty.all(colorScheme.onSurface),
        yearStyle: baseTextStyle(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static TextStyle baseTextStyle(Color color) => TextStyle(color: color);
}
