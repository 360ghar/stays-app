import 'package:flutter/material.dart';

import '../../theme/app_dimensions.dart';
import '../../theme/theme_extensions.dart';

/// Base card widget that provides common styling and behavior for property cards.
///
/// This widget encapsulates the shared visual design patterns used across
/// PropertyCard, PropertyGridCard, and other card types, including:
/// - Consistent border radius
/// - Elevation and shadow handling
/// - Dark mode support
/// - Inkwell splash effects
abstract class BaseCard extends StatelessWidget {
  const BaseCard({
    super.key,
    required this.onTap,
    this.borderRadius,
    this.elevation,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadiusValue = AppDimensions.radiusLg,
  });

  final VoidCallback onTap;
  final BorderRadius? borderRadius;
  final double? elevation;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double borderRadiusValue;

  /// Builds the card content.
  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(borderRadiusValue);
    final effectiveElevation = elevation ?? (isDark ? 2.0 : 6.0);
    final effectiveBackgroundColor = backgroundColor ??
        colors.surface.withValues(alpha: isDark ? 0.97 : 0.995);

    final effectiveMargin = margin ??
        const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        );

    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: AppDimensions.cardPaddingMd,
          vertical: AppDimensions.cardPaddingSm,
        );

    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.4 : 0.12);

    return Container(
      margin: effectiveMargin,
      child: Material(
        color: Colors.transparent,
        elevation: effectiveElevation,
        shadowColor: shadowColor,
        borderRadius: effectiveBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                effectiveBackgroundColor,
                Color.alphaBlend(
                  colors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                  colors.surface.withValues(alpha: isDark ? 0.95 : 0.985),
                ),
              ],
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: effectiveBorderRadius,
            splashColor: colors.primary.withValues(alpha: 0.12),
            highlightColor: colors.primary.withValues(alpha: 0.06),
            child: Padding(
              padding: effectivePadding,
              child: buildContent(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Base image card widget for cards with hero images at the top.
abstract class BaseImageCard extends StatelessWidget {
  const BaseImageCard({
    super.key,
    required this.onTap,
    required this.imageUrl,
    required this.heroTag,
    this.borderRadius,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.aspectRatio = AppDimensions.cardLandscapeRatio,
    this.overlayInset,
  });

  final VoidCallback onTap;
  final String? imageUrl;
  final String heroTag;
  final BorderRadius? borderRadius;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final double aspectRatio;
  final double? overlayInset;

  /// Builds the overlay content on top of the image.
  Widget? buildOverlayContent(BuildContext context);

  /// Builds the content below the image.
  Widget? buildBelowImageContent(BuildContext context) => null;

  /// Builds the placeholder widget when no image is available.
  Widget buildPlaceholder(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      alignment: Alignment.center,
      child: Icon(
        Icons.hotel,
        size: 48,
        color: colors.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(18);
    final effectiveInset = overlayInset ?? AppDimensions.cardPaddingLg.toDouble();

    final imageWidget = imageUrl != null && imageUrl!.isNotEmpty
        ? _buildCachedImage(context)
        : buildPlaceholder(context);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveBorderRadius,
          elevation: context.isDark ? 2.0 : 6.0,
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageWidget,
                      // Subtle gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0),
                                Colors.black.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Favorite button
                      if (onFavoriteToggle != null)
                        _buildFavoriteButton(context, effectiveInset),
                      // Overlay content
                      if (buildOverlayContent(context) != null)
                        buildOverlayContent(context)!,
                    ],
                  ),
                ),
                // Content below image
                if (buildBelowImageContent(context) != null)
                  buildBelowImageContent(context)!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCachedImage(BuildContext context) {
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => buildPlaceholder(context),
    );
  }

  Widget _buildFavoriteButton(BuildContext context, double inset) {
    final colors = context.colors;
    return Positioned(
      top: inset,
      right: inset,
      child: Material(
        color: colors.surface.withValues(alpha: context.isDark ? 0.6 : 0.92),
        shape: const CircleBorder(),
        elevation: context.isDark ? 0 : 4,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onFavoriteToggle,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? colors.error : colors.onSurface,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
