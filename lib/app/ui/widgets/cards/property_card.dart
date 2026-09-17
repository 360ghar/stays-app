import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/ui/widgets/common/cached_image.dart';

import '../../theme/theme_extensions.dart';

const double _propertyCardCornerRadius = 18.0;
const double _propertyCardShadowBlur = 20.0;
const EdgeInsets _propertyCardMargin = EdgeInsets.only(right: 14);

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    required this.property,
    required this.onTap,
    super.key,
    this.onFavoriteToggle,
    this.width = 248,
    this.height = 184,
    this.showPrice = true,
    this.showRating = false,
    this.heroPrefix,
    this.isFavorite = false,
  });
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final double width;
  final double height;
  final bool showPrice;
  final bool showRating;
  final String? heroPrefix;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(_propertyCardCornerRadius);
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.12);

    // Build semantic description for accessibility
    final semanticLabel = StringBuffer();
    semanticLabel.write(property.name);
    semanticLabel.write(', ${property.fullAddress}');
    if (showPrice) {
      semanticLabel.write(', ${property.displayPrice} per night');
    }
    if (isFavorite) {
      semanticLabel.write(', saved to wishlist');
    }

    return Semantics(
      label: semanticLabel.toString(),
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          margin: _propertyCardMargin,
          child: Hero(
            tag: '${heroPrefix ?? 'property'}-${property.id}',
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: _propertyCardShadowBlur,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(context),
                      _buildGradientOverlay(),
                      _buildContent(context),
                      if (onFavoriteToggle != null)
                        _buildFavoriteButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    // Canonical image fallback: placeholder, shimmer, and error states all
    // live in [CachedImage]. Do not re-add local placeholder()/Shimmer
    // blocks here; fix them in cached_image.dart instead.
    return CachedImage(imageUrl: property.displayImage);
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_propertyCardCornerRadius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.75),
            ],
            stops: const [0.35, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            property.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            property.fullAddress,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showPrice)
                Text(
                  '${property.displayPrice}/night',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (showRating && property.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      property.ratingText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    if (property.reviewsCount != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${property.reviewsCount})',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    final colors = context.colors;
    return Positioned(
      top: 12,
      right: 12,
      child: Semantics(
        label: isFavorite ? 'Remove from wishlist' : 'Add to wishlist',
        button: true,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onFavoriteToggle,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface.withValues(
                alpha: (Theme.of(context).brightness == Brightness.dark)
                    ? 0.55
                    : 0.3,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? colors.error : Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class PropertyCardShimmer extends StatelessWidget {
  const PropertyCardShimmer({super.key, this.width = 248, this.height = 184});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final borderRadius = BorderRadius.circular(_propertyCardCornerRadius);
    final shadowColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.1);

    return Container(
      width: width,
      height: height,
      margin: _propertyCardMargin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: _propertyCardShadowBlur,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Shimmer.fromColors(
            baseColor: colors.surfaceContainerHighest.withValues(alpha: 0.38),
            highlightColor: colors.surfaceContainerHighest.withValues(
              alpha: 0.16,
            ),
            child: Container(color: colors.surface),
          ),
        ),
      ),
    );
  }
}
