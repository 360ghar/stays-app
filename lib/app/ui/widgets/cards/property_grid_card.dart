import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/models/property_model.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_animations.dart';
import '../common/animated_widgets.dart';
import '../common/animated_favorite_button.dart';

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

    return AnimatedScaleWrapper(
      onTap: onTap,
      scaleFactor: 0.97,
      duration: AppAnimations.cardPressDuration,
      curve: AppAnimations.cardPressCurve,
      child: Material(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasBoundedHeight = constraints.hasBoundedHeight &&
                  constraints.maxHeight.isFinite;
              if (!hasBoundedHeight) {
                return Column(
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
                );
              }

              const imageFlex = 6;
              const infoFlex = 5;
              return Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: imageFlex, child: _buildImage(context)),
                  Expanded(
                    flex: infoFlex,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding,
                      ),
                      child: _buildInfo(context),
                    ),
                  ),
                ],
              );
            },
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
    // Use 4/3 ratio for larger images instead of 3/2
    final aspectRatio = isCompact ? 1.9 : 4 / 3;

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
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mutedColor = colors.onSurface.withValues(alpha: 0.68);
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

  Positioned _buildFavoriteButton(BuildContext context, double inset) {
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      top: inset,
      right: inset,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: context.isDark ? 0.6 : 0.92),
          shape: BoxShape.circle,
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: AnimatedFavoriteButton(
          isFavorite: isFavorite,
          onToggle: (_) => onFavoriteToggle?.call(),
          size: 20,
          normalColor: colors.onSurface.withValues(alpha: 0.7),
          favoriteColor: colors.error,
          hasBackground: false,
        ),
      ),
    );
  }

}
