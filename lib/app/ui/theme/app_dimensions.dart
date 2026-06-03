import 'package:flutter/widgets.dart';

/// Responsive design system constants for the app.
class AppDimensions {
  // Spacing scale
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  // Legacy support
  static const double padding = lg;
  static const double radius = radiusMd;

  // Border radius scale
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;

  // Card aspect ratios
  static const double cardPortraitRatio = 3 / 4; // Taller cards
  static const double cardLandscapeRatio = 4 / 3; // Wider images
  static const double cardSquareRatio = 1.0;

  // Responsive card sizing (percentages of screen width)
  static const double cardWidthFraction = 0.75; // 75% of screen width
  static const double cardCompactWidthFraction = 0.65; // 65% for compact cards

  // Image quality for caching
  static const int imageCacheWidth = 600;
  static const int imageDiskCacheWidth = 1200;

  // Hero image height (percentage of screen height)
  static const double heroImageHeightFraction = 0.40; // 40% of screen height
  static const double mapHeight = 200; // Fixed map height in dp

  // Section spacing
  static const double sectionSpacingXs = 24;
  static const double sectionSpacingSm = 28;
  static const double sectionSpacingMd = 32;
  static const double sectionSpacingLg = 36;
  static const double sectionSpacingXl = 40;

  // Card content padding
  static const double cardPaddingSm = 14;
  static const double cardPaddingMd = 16;
  static const double cardPaddingLg = 18;

  // Explore page specific dimensions
  static const double heroSectionHeight = 100;
  static const double featuredCardHeight = 180;
  static const double horizontalSectionHeight = 220;
  static const double exploreSectionSpacing = 20;
  static const double exploreSectionSpacingLarge = 28;
  static const double featuredCardAspectRatio = 16 / 9;
}

/// Extension to provide responsive dimensions based on screen size.
extension ResponsiveDimensions on BuildContext {
  /// Gets the screen width.
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Gets the screen height.
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Calculates responsive card width (75% of screen width by default).
  double responsiveCardWidth([double fraction = AppDimensions.cardWidthFraction]) =>
      screenWidth * fraction;

  /// Calculates responsive hero image height (40% of screen height).
  double get responsiveHeroHeight => screenHeight * AppDimensions.heroImageHeightFraction;
}
