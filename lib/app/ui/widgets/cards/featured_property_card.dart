import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';

/// A large, prominent featured property card for the Explore page.
/// Displays a full-width card with cinematic 16:9 aspect ratio, gradient overlay,
/// and "Nearest to you" badge.
class FeaturedPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final String? heroPrefix;

  const FeaturedPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(22);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: colors.primary.withValues(alpha: 0.15),
        highlightColor: colors.primary.withValues(alpha: 0.08),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 180,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
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
                _buildNearestBadge(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final heroTag = '${heroPrefix ?? 'featured'}-${property.id}';
    final colors = Theme.of(context).colorScheme;
    final imageUrl = property.displayImage;

    Widget placeholder() {
      return Container(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: Icon(
          Icons.hotel,
          size: 56,
          color: colors.onSurface.withValues(alpha: 0.4),
        ),
      );
    }

    final image = imageUrl != null && imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: colors.surfaceContainerHighest,
              highlightColor: colors.surface,
              child: Container(color: colors.surface),
            ),
            errorWidget: (_, __, ___) => placeholder(),
          )
        : placeholder();

    return Hero(tag: heroTag, child: image);
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.85),
            ],
            stops: const [0.3, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final textStyles = context.textStyles;
    final colors = context.colors;

    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Property type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property.propertyTypeDisplay,
                    style: textStyles.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Property name
                Text(
                  property.name,
                  style: textStyles.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.fullAddress,
                        style: textStyles.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Price and rating row
                Row(
                  children: [
                    Text(
                      property.displayPrice,
                      style: textStyles.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' / night',
                      style: textStyles.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (property.rating != null && property.rating! > 0) ...[
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        property.ratingText,
                        style: textStyles.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    final colors = context.colors;
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        color: colors.surface.withValues(alpha: context.isDark ? 0.55 : 0.85),
        shape: const CircleBorder(),
        elevation: context.isDark ? 0 : 6,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onFavoriteToggle,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? colors.error : Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearestBadge(BuildContext context) {
    final distance = property.distanceKm;
    final colors = context.colors;

    return Positioned(
      left: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.near_me, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Nearest to you',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            if (distance != null && distance > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact horizontal strip for the featured/nearest property on Explore.
class FeaturedPropertyStrip extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final String? heroPrefix;

  const FeaturedPropertyStrip({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(16);
    final imageSize = 88.0;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: colors.primary.withValues(alpha: 0.12),
        highlightColor: colors.primary.withValues(alpha: 0.06),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: borderRadius,
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _FeaturedStripImage(
                property: property,
                heroPrefix: heroPrefix,
                size: imageSize,
              ),
              const SizedBox(width: 12),
              Expanded(child: _FeaturedStripInfo(property: property)),
              if (onFavoriteToggle != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? colors.error : colors.onSurface,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedStripImage extends StatelessWidget {
  final Property property;
  final String? heroPrefix;
  final double size;

  const _FeaturedStripImage({
    required this.property,
    required this.size,
    this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final heroTag = '${heroPrefix ?? 'featured_strip'}-${property.id}';
    final imageUrl = property.displayImage;

    Widget placeholder() {
      return Container(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: Icon(
          Icons.hotel,
          size: 32,
          color: colors.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    final image = imageUrl != null && imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: colors.surfaceContainerHighest,
            ),
            errorWidget: (_, __, ___) => placeholder(),
          )
        : placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: Hero(tag: heroTag, child: image),
      ),
    );
  }
}

class _FeaturedStripInfo extends StatelessWidget {
  final Property property;

  const _FeaturedStripInfo({required this.property});

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.propertyTypeDisplay,
          style: textStyles.labelSmall?.copyWith(
            color: colors.primary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          property.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          property.fullAddress,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyles.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          property.displayPrice,
          style: textStyles.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// A shimmer placeholder for the featured strip.
class FeaturedPropertyStripShimmer extends StatelessWidget {
  const FeaturedPropertyStripShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(16);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 108,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Shimmer.fromColors(
          baseColor: colors.surfaceContainerHighest,
          highlightColor: colors.surface,
          child: Container(color: colors.surface),
        ),
      ),
    );
  }
}

/// A shimmer placeholder for the featured property card.
class FeaturedPropertyCardShimmer extends StatelessWidget {
  const FeaturedPropertyCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(22);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Shimmer.fromColors(
          baseColor: colors.surfaceContainerHighest,
          highlightColor: colors.surface,
          child: Container(color: colors.surface),
        ),
      ),
    );
  }
}
