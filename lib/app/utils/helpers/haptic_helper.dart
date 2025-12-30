import 'package:flutter/services.dart';

/// Helper class for providing haptic feedback throughout the app.
/// Provides consistent haptic patterns for different interaction types.
class HapticHelper {
  HapticHelper._();

  /// Light impact feedback for subtle interactions
  /// Use for: Tab switches, toggles, selections
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact feedback for standard interactions
  /// Use for: Button taps, list item selections
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback for significant interactions
  /// Use for: Important confirmations, errors
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click feedback
  /// Use for: Picker selections, date changes
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate feedback for alerts
  /// Use for: Errors, warnings, important notifications
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Success feedback pattern
  /// Use for: Successful operations, confirmations
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Error feedback pattern
  /// Use for: Failed operations, validation errors
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  /// Warning feedback pattern
  /// Use for: Potentially destructive actions
  static Future<void> warning() async {
    await HapticFeedback.mediumImpact();
  }

  /// Favorite toggle feedback
  /// Use for: Adding/removing from wishlist
  static Future<void> favoriteToggle() async {
    await HapticFeedback.lightImpact();
  }

  /// Pull-to-refresh feedback
  /// Use for: When refresh is triggered
  static Future<void> refresh() async {
    await HapticFeedback.mediumImpact();
  }

  /// Navigation feedback
  /// Use for: Tab changes, page transitions
  static Future<void> navigation() async {
    await HapticFeedback.selectionClick();
  }
}
