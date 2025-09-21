import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/models/property_model.dart';
import '../../theme/theme_extensions.dart';

class PropertyGridCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final String? heroPrefix;

  const PropertyGridCard({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        color: colors.surface,
        elevation: 2,
        shadowColor:
            context.isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: _buildInfo(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final heroTag = '${heroPrefix ?? 'grid'}-${property.id}';
    final img = property.displayImage;
    final colors = Theme.of(context).colorScheme;

    // If no image URL is available, show placeholder directly
    if (img == null || img.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: Container(
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

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(14),
        topRight: Radius.circular(14),
      ),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: img,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      highlightColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Container(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                errorWidget:
                    (_, __, ___) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.photo,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 32,
                      ),
                    ),
              ),
            ),
            if (property.hasVirtualTour) _buildTourBadge(context),
            if (onFavoriteToggle != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: colors.surface.withValues(
                    alpha: context.isDark ? 0.55 : 0.35,
                  ),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onFavoriteToggle,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? colors.error : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            if (property.distanceKm != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${property.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourBadge(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.threesixty, size: 14, color: Colors.white),
            SizedBox(width: 4),
            Text(
              '360 Tour',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                property.fullAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(property.ratingText, style: theme.textTheme.bodyMedium),
                if (property.reviewsCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${property.reviewsCount})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '${property.displayPrice}/night',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        if (property.description != null && property.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              property.description!,
              maxLines: 2,
              overflow: TextOverflow.fade,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }
}
