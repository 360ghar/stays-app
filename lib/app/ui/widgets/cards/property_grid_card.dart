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
  final bool isCompact;

  const PropertyGridCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.heroPrefix,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(isCompact ? 16 : 18);
    final horizontalPadding = isCompact ? 14.0 : 16.0;
    final verticalPadding = isCompact ? 12.0 : 14.0;
    final elevation = isCompact
        ? (context.isDark ? 1.5 : 5.0)
        : (context.isDark ? 2.0 : 6.0);

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.12),
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.surface.withValues(alpha: context.isDark ? 0.97 : 0.995),
              Color.alphaBlend(
                colors.primary.withValues(alpha: context.isDark ? 0.08 : 0.04),
                colors.surface.withValues(alpha: context.isDark ? 0.95 : 0.985),
              ),
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: colors.primary.withValues(alpha: 0.12),
          highlightColor: colors.primary.withValues(alpha: 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(context),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: _buildInfo(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final heroTag = '${heroPrefix ?? 'grid'}-${property.id}';
    final colors = Theme.of(context).colorScheme;
    final imageUrl = property.displayImage;
    final overlayInset = isCompact ? 12.0 : 14.0;
    final aspectRatio = isCompact ? 2.05 : 3 / 2;

    Widget placeholder() {
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

    final image = imageUrl != null && imageUrl.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: colors.surfaceContainerHighest,
              highlightColor: colors.surface,
              child: Container(color: colors.surface),
            ),
            errorWidget: (_, __, ___) => Container(
              color: colors.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.photo,
                color: colors.onSurface.withValues(alpha: 0.5),
                size: 32,
              ),
            ),
          )
        : placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isCompact ? 16 : 18),
        topRight: Radius.circular(isCompact ? 16 : 18),
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: heroTag, child: image),
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
            if (onFavoriteToggle != null)
              _buildFavoriteButton(context, overlayInset),
            if (property.distanceKm != null && property.distanceKm! > 0)
              _buildDistanceBadge(overlayInset),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedColor = colors.onSurface.withValues(alpha: 0.68);
    final metaDetails = _buildMetaDetails(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      height: 1.2,
      fontSize: isCompact
          ? (theme.textTheme.titleMedium?.fontSize ?? 18) - 1
          : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.propertyTypeDisplay,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: colors.primary.withValues(alpha: 0.75),
                    ),
                  ),
                  SizedBox(height: isCompact ? 4 : 6),
                  Text(
                    property.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ],
              ),
            ),
            SizedBox(width: isCompact ? 10 : 12),
            _buildPriceChip(context),
          ],
        ),
        SizedBox(height: isCompact ? 6 : 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: isCompact ? 14 : 16,
              color: mutedColor,
            ),
            SizedBox(width: isCompact ? 3 : 4),
            Expanded(
              child: Text(
                property.fullAddress,
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: mutedColor,
                  height: isCompact ? 1.3 : 1.35,
                ),
              ),
            ),
          ],
        ),
        if (metaDetails != null) ...[
          SizedBox(height: isCompact ? 10 : 12),
          metaDetails,
        ],
      ],
    );
  }

  Widget _buildPriceChip(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    final horizontal = isCompact ? 10.0 : 12.0;
    final vertical = isCompact ? 5.0 : 6.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? colors.primaryContainer.withValues(alpha: 0.25)
            : colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: Text(
          property.displayPrice,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget? _buildMetaDetails(BuildContext context) {
    final chips = <Widget>[];

    void addChip(IconData icon, String label) {
      chips.add(_buildMetaChip(context, icon, label));
    }

    if (property.bedrooms != null && property.bedrooms! > 0) {
      final beds = property.bedrooms!;
      addChip(Icons.bed_outlined, '$beds ${beds == 1 ? 'Bed' : 'Beds'}');
    }

    if (property.bathrooms != null && property.bathrooms! > 0) {
      final baths = property.bathrooms!;
      addChip(
        Icons.bathtub_outlined,
        '$baths ${baths == 1 ? 'Bath' : 'Baths'}',
      );
    }

    if (property.squareFeet != null && property.squareFeet! > 0) {
      final sqft = property.squareFeet!;
      final sqftText = sqft.remainder(1) == 0
          ? sqft.toStringAsFixed(0)
          : sqft.toStringAsFixed(1);
      addChip(Icons.square_foot, '$sqftText sqft');
    }

    if (property.rating != null && property.rating! > 0) {
      addChip(Icons.star_rate_rounded, property.ratingText);
    }

    if (chips.isEmpty) return null;
    return Wrap(
      spacing: isCompact ? 6 : 8,
      runSpacing: isCompact ? 6 : 8,
      children: chips,
    );
  }

  Widget _buildMetaChip(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    final iconSize = isCompact ? 13.0 : 14.0;
    final textStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: colors.onSurface.withValues(alpha: 0.75),
      fontWeight: FontWeight.w500,
      fontSize: isCompact ? 12.5 : null,
    );
    final horizontal = isCompact ? 8.0 : 10.0;
    final vertical = isCompact ? 5.0 : 6.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withValues(
          alpha: context.isDark ? 0.35 : 0.6,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            SizedBox(width: isCompact ? 3 : 4),
            Text(label, style: textStyle),
          ],
        ),
      ),
    );
  }

  Positioned _buildFavoriteButton(BuildContext context, double inset) {
    final colors = Theme.of(context).colorScheme;
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

  Positioned _buildDistanceBadge(double inset) {
    return Positioned(
      left: inset,
      bottom: inset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 9 : 10,
            vertical: isCompact ? 4 : 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, color: Colors.white, size: 14),
              SizedBox(width: isCompact ? 3 : 4),
              Text(
                '${property.distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
