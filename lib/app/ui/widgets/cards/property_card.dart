import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stays_app/app/data/models/property_model.dart';

import '../../theme/theme_extensions.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final double width;
  final double height;
  final bool showPrice;
  final bool showRating;
  final String? heroPrefix;
  final bool isFavorite;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    this.width = 280,
    this.height = 200,
    this.showPrice = true,
    this.showRating = true,
    this.heroPrefix,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 16),
        child: Hero(
          tag: '${heroPrefix ?? 'property'}-${property.id}',
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                _buildImage(context),
                _buildGradientOverlay(),
                _buildContent(context),
                if (onFavoriteToggle != null) _buildFavoriteButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: property.displayImage,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          highlightColor: colors.surfaceContainerHighest.withValues(
            alpha: 0.15,
          ),
          child: Container(color: colors.surface),
        ),
        errorWidget: (context, url, error) => Container(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Icon(
            Icons.hotel,
            size: 48,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
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
    );
  }
}

class PropertyCardShimmer extends StatelessWidget {
  final double width;
  final double height;

  const PropertyCardShimmer({super.key, this.width = 280, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 16),
      child: Shimmer.fromColors(
        baseColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        highlightColor: colors.surfaceContainerHighest.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
