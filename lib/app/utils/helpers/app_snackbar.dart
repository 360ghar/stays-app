import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Centralized snackbar helper for consistent styling across the app.
///
/// Usage:
/// ```dart
/// AppSnackbar.success(title: 'Success', message: 'Operation completed');
/// AppSnackbar.error(title: 'Error', message: 'Something went wrong');
/// AppSnackbar.warning(title: 'Warning', message: 'Please check your input');
/// AppSnackbar.info(title: 'Info', message: 'New update available');
/// ```
class AppSnackbar {
  AppSnackbar._();

  static const Duration _defaultDuration = Duration(seconds: 3);
  static const Duration _errorDuration = Duration(seconds: 4);
  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const double _borderRadius = 16.0;
  static const EdgeInsets _margin = EdgeInsets.all(16);

  /// Check if GetX is ready to show snackbars (has valid overlay context)
  static bool get _canShowSnackbar {
    try {
      // Try to access the current route - if it fails, navigator isn't ready
      Get.currentRoute;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Show a success snackbar
  static void success({
    required String title,
    required String message,
    Duration? duration,
  }) {
    final colors = Get.theme.colorScheme;
    _show(
      title: title,
      message: message,
      backgroundColor: colors.primaryContainer.withValues(alpha: 0.95),
      textColor: colors.onPrimaryContainer,
      icon: Icons.check_circle_rounded,
      iconColor: colors.primary,
      duration: duration ?? _defaultDuration,
    );
  }

  /// Show an error snackbar
  static void error({
    required String title,
    required String message,
    Duration? duration,
  }) {
    final colors = Get.theme.colorScheme;
    _show(
      title: title,
      message: message,
      backgroundColor: colors.errorContainer.withValues(alpha: 0.95),
      textColor: colors.onErrorContainer,
      icon: Icons.error_rounded,
      iconColor: colors.error,
      duration: duration ?? _errorDuration,
    );
  }

  /// Show a warning snackbar
  static void warning({
    required String title,
    required String message,
    Duration? duration,
  }) {
    _show(
      title: title,
      message: message,
      backgroundColor: Colors.amber.shade100.withValues(alpha: 0.95),
      textColor: Colors.amber.shade900,
      icon: Icons.warning_rounded,
      iconColor: Colors.amber.shade700,
      duration: duration ?? _defaultDuration,
    );
  }

  /// Show an info snackbar
  static void info({
    required String title,
    required String message,
    Duration? duration,
  }) {
    final colors = Get.theme.colorScheme;
    _show(
      title: title,
      message: message,
      backgroundColor: colors.secondaryContainer.withValues(alpha: 0.95),
      textColor: colors.onSecondaryContainer,
      icon: Icons.info_rounded,
      iconColor: colors.secondary,
      duration: duration ?? _defaultDuration,
    );
  }

  /// Show a simple message snackbar (no title)
  static void show(String message, {bool isError = false}) {
    if (!_canShowSnackbar) return; // Skip if GetX overlay isn't ready
    final colors = Get.theme.colorScheme;
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? colors.errorContainer.withValues(alpha: 0.95)
          : colors.surfaceContainerHighest.withValues(alpha: 0.95),
      colorText: isError ? colors.onErrorContainer : colors.onSurface,
      borderRadius: _borderRadius,
      margin: _margin,
      duration: isError ? _errorDuration : _defaultDuration,
      animationDuration: _animationDuration,
      titleText: const SizedBox.shrink(),
    );
  }

  /// Internal method to show styled snackbar
  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
  }) {
    if (!_canShowSnackbar) return; // Skip if GetX overlay isn't ready
    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      borderRadius: _borderRadius,
      margin: _margin,
      duration: duration,
      animationDuration: _animationDuration,
      titleText: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.85),
          fontSize: 14,
        ),
      ),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  /// Dismiss current snackbar
  static void dismiss() {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }
}
