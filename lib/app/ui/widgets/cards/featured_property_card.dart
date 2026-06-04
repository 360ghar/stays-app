import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';
import 'package:stays_app/app/ui/theme/app_animations.dart';
import 'package:stays_app/app/ui/widgets/common/animated_widgets.dart';
import 'package:stays_app/app/ui/widgets/common/animated_favorite_button.dart';

/// A large, prominent featured property card for the Explore page.
/// Displays a full-width card with cinematic 16:9 aspect ratio, gradient overlay,
/// and "Nearest to you" badge with premium animations and effects.
class FeaturedPropertyCard extends StatefulWidget {
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
  State<FeaturedPropertyCard> createState() => _FeaturedPropertyCardState();
}

class _FeaturedPropertyCardState extends State<FeaturedPropertyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(24);

    return AnimatedScaleWrapper(
      onTap: widget.onTap,
      scaleFactor: 0.97,
      duration: AppAnimations.cardPressDuration,
      curve: AppAnimations.cardPressCurve,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.12),
              blurRadius: 32,
              offset: const Offset(0, 16),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: colors.primary.withValues(alpha: context.isDark ? 0.15 : 0.08),
              blurRadius: 24,
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
              _buildShimmerEffect(),
              _buildContent(context),
              if (widget.onFavoriteToggle != null)
                _buildFavoriteButton(context),
              _buildNearestBadge(context),
              _buildGlossOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlossOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
                Colors.transparent,
                Colors.white.withValues(alpha: 0.02),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
                transform: _SlidingGradientTransform(
                  slidePercent: _shimmerController.value,
                ),
              ).createShader(bounds);
            },
            blendMode: BlendMode.overlay,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final heroTag = '${widget.heroPrefix ?? 'featured'}-${widget.property.id}';
    final colors = Theme.of(context).colorScheme;
    final imageUrl = widget.property.displayImage;

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.property.propertyTypeDisplay,
                    style: textStyles.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.property.name,
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
                        widget.property.fullAddress,
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
                Row(
                  children: [
                    Text(
                      widget.property.displayPrice,
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
                    if (widget.property.rating != null && widget.property.rating! > 0) ...[
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.property.ratingText,
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
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: context.isDark ? 0.55 : 0.85),
          shape: BoxShape.circle,
          boxShadow: context.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: AnimatedFavoriteButton(
          isFavorite: widget.isFavorite,
          onToggle: (_) => widget.onFavoriteToggle?.call(),
          size: 22,
          normalColor: Colors.white.withValues(alpha: 0.9),
          favoriteColor: colors.error,
          hasBackground: false,
        ),
      ),
    );
  }

  Widget _buildNearestBadge(BuildContext context) {
    final distance = widget.property.distanceKm;
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

    return AnimatedScaleWrapper(
      onTap: onTap,
      scaleFactor: 0.97,
      duration: AppAnimations.cardPressDuration,
      curve: AppAnimations.cardPressCurve,
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
              size: 88,
            ),
            const SizedBox(width: 12),
            Expanded(child: _FeaturedStripInfo(property: property)),
            if (onFavoriteToggle != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AnimatedFavoriteButton(
                  isFavorite: isFavorite,
                  onToggle: (_) => onFavoriteToggle?.call(),
                  size: 20,
                  normalColor: colors.onSurface.withValues(alpha: 0.7),
                  favoriteColor: colors.error,
                  hasBackground: false,
                ),
              ),
          ],
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
    final borderRadius = BorderRadius.circular(24);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: colors.primary.withValues(alpha: context.isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
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

/// Gradient transform for sliding shimmer effect.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * slidePercent,
      0.0,
      0.0,
    );
  }
}
