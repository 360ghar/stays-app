import 'package:flutter/material.dart';

/// Centralized animation configuration for the app.
/// Inspired by top-tier apps like Airbnb, Instagram, and Spotify.
class AppAnimations {
  AppAnimations._();

  // ===============================================
  // DURATIONS
  // ===============================================

  /// Instant - for immediate feedback (50ms)
  static const Duration instant = Duration(milliseconds: 50);

  /// Fast - for quick micro-interactions (150ms)
  static const Duration fast = Duration(milliseconds: 150);

  /// Medium - for standard transitions (250ms)
  static const Duration medium = Duration(milliseconds: 250);

  /// Normal - for general animations (300ms)
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow - for complex transitions (400ms)
  static const Duration slow = Duration(milliseconds: 400);

  /// Slower - for major layout changes (500ms)
  static const Duration slower = Duration(milliseconds: 500);

  /// Extra slow - for hero animations (600ms)
  static const Duration extraSlow = Duration(milliseconds: 600);

  // ===============================================
  // CURVES
  // ===============================================

  /// Ease out - starts fast, ends slow (most common)
  static const Curve easeOut = Curves.easeOut;

  /// Ease in out - smooth acceleration and deceleration
  static const Curve easeInOut = Curves.easeInOut;

  /// Ease out cubic - premium feel, used by Apple
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Ease out quart - more dramatic slowdown
  static const Curve easeOutQuart = Curves.easeOutQuart;

  /// Ease out back - slight overshoot for playful feel
  static const Curve easeOutBack = Curves.easeOutBack;

  /// Ease out expo - exponential deceleration
  static const Curve easeOutExpo = Curves.easeOutExpo;

  /// Bounce - for attention-grabbing elements
  static const Curve bounce = Curves.bounceOut;

  /// Elastic - for spring-like effects
  static const Curve elastic = Curves.elasticOut;

  /// Fast out slow in - Material Design standard
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // ===============================================
  // COMMON CURVE + DURATION COMBINATIONS
  // ===============================================

  /// Standard card interaction
  static const Curve cardPressCurve = easeOutCubic;
  static const Duration cardPressDuration = fast;

  /// Page transition
  static const Curve pageTransitionCurve = fastOutSlowIn;
  static const Duration pageTransitionDuration = normal;

  /// Dialog/bottom sheet
  static const Curve sheetCurve = easeOutCubic;
  static const Duration sheetDuration = medium;

  /// List item animation
  static const Curve listItemCurve = easeOut;
  static const Duration listItemDuration = medium;

  /// Favorite animation
  static const Curve favoriteCurve = elastic;
  static const Duration favoriteDuration = slower;

  /// Button press
  static const Curve buttonPressCurve = easeOutCubic;
  static const Duration buttonPressDuration = fast;

  /// Stagger delay between list items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Hero animation
  static const Curve heroCurve = fastOutSlowIn;
  static const Duration heroDuration = extraSlow;
}

/// Extension for easy access to animation values
extension AppAnimationsExtension on BuildContext {
  /// Access animation configurations via context
  AppAnimations get animations => AppAnimations._();
}
