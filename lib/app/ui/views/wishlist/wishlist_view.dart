import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/ui/widgets/common/location_filter_app_bar.dart';

import '../../../controllers/wishlist_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../routes/app_routes.dart';
import '../../theme/theme_extensions.dart';

class WishlistView extends GetView<WishlistController> {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final filterController = Get.find<FilterController>();
    final filtersRx = filterController.rxFor(FilterScope.wishlist);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: LocationFilterAppBar(
        scope: FilterScope.wishlist,
        trailingActions: [
          Obx(
            () => controller.wishlistItems.isNotEmpty
                ? IconButton(
                    tooltip: 'Clear wishlist',
                    onPressed: controller.clearWishlist,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final hasFilters = filtersRx.value.isNotEmpty;
        if (controller.wishlistItems.isEmpty) {
          if (hasFilters && controller.totalItems > 0) {
            return _buildFilteredEmptyState(context, filterController);
          }
          return _buildEmptyState(context);
        }

        final items = controller.wishlistItems;
        final tags = filtersRx.value.activeTags();
        final showTags = tags.isNotEmpty;
        final itemCount = items.length + (showTags ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () async => await controller.loadWishlist(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (showTags && index == 0) {
                return _buildFilterTags(context, tags, filterController);
              }
              final propertyIndex = showTags ? index - 1 : index;
              final item = items[propertyIndex];
              return _buildWishlistCard(context, item);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: colors.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Your wishlist is empty',
              style: textStyles.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save your favorite places to stay\nand access them anytime',
              textAlign: TextAlign.center,
              style: textStyles.bodyMedium?.copyWith(
                fontSize: 16,
                color: colors.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Exploring',
                style: textStyles.labelLarge?.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState(
    BuildContext context,
    FilterController filterController,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 80,
              color: colors.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'No stays match these filters',
              style: textStyles.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Adjust your filters or clear them to see every favorite stay.',
              textAlign: TextAlign.center,
              style: textStyles.bodyMedium?.copyWith(
                fontSize: 16,
                color: colors.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => filterController.openFilterSheet(
                context,
                FilterScope.wishlist,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Adjust Filters',
                style: textStyles.labelLarge?.copyWith(fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () => filterController.clear(FilterScope.wishlist),
              style: TextButton.styleFrom(foregroundColor: colors.primary),
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTags(
    BuildContext context,
    List<String> tags,
    FilterController filterController,
  ) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map(
                (tag) => Chip(
                  label: Text(
                    tag,
                    style: textStyles.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  backgroundColor: colors.primaryContainer,
                ),
              )
              .toList(),
        ),
        TextButton(
          onPressed: () => filterController.clear(FilterScope.wishlist),
          style: TextButton.styleFrom(foregroundColor: colors.primary),
          child: const Text('Clear filters'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildWishlistCard(BuildContext context, Property item) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final isDark = context.isDark;
    final locationLine = _formatLocationLine(item);
    final featureSummary = _formatFeatureSummary(item);
    final ratingLabel = item.rating?.toStringAsFixed(1);
    final hasRating = ratingLabel != null;
    final reviewsLabel = item.reviewsCount != null && item.reviewsCount! > 0
        ? '(${item.reviewsCount})'
        : null;
    final hasDistance = item.distanceKm != null && item.distanceKm! > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.elevatedSurface(isDark ? 0.14 : 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: isDark ? 0.24 : 0.16),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.toNamed(
            Routes.listingDetail.replaceFirst(':id', item.id.toString()),
            arguments: item,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 118,
                  child: Hero(
                    tag: 'wishlist-${item.id}',
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: _buildWishlistImage(context, item),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: colors.surface.withValues(
                              alpha: isDark ? 0.82 : 0.92,
                            ),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () =>
                                  controller.removeFromWishlist(item.id),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  Icons.favorite,
                                  size: 18,
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      if (locationLine != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyles.bodySmall?.copyWith(
                                  color:
                                      colors.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (featureSummary.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              featureSummary,
                              style: textStyles.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${item.displayPrice}/night',
                              style: textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: _buildTrailingMeta(
                            context: context,
                            ratingLabel: ratingLabel,
                            reviewsLabel: reviewsLabel,
                            hasRating: hasRating,
                            hasDistance: hasDistance,
                            distanceKm: item.distanceKm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistImage(BuildContext context, Property property) {
    final colors = context.colors;
    final imageUrl = property.displayImage;

    Widget placeholder() {
      return Container(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: Icon(
          Icons.home_work_outlined,
          size: 32,
          color: colors.onSurface.withValues(alpha: 0.55),
        ),
      );
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        highlightColor: colors.surface.withValues(alpha: 0.2),
        child: Container(color: colors.surface),
      ),
      errorWidget: (context, url, error) => placeholder(),
    );
  }

  List<Widget> _buildTrailingMeta({
    required BuildContext context,
    required String? ratingLabel,
    required String? reviewsLabel,
    required bool hasRating,
    required bool hasDistance,
    required double? distanceKm,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final widgets = <Widget>[];

    if (hasRating && ratingLabel != null) {
      widgets.addAll([
        Icon(
          Icons.star_rounded,
          size: 16,
          color: Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          ratingLabel,
          style: textStyles.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ]);

      if (reviewsLabel != null) {
        widgets.addAll([
          const SizedBox(width: 4),
          Text(
            reviewsLabel,
            style: textStyles.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ]);
      }
    }

    if (hasDistance && distanceKm != null) {
      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(width: 12));
      }
      widgets.addAll([
        Icon(
          Icons.directions_walk_outlined,
          size: 16,
          color: colors.onSurface.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDistance(distanceKm),
          style: textStyles.bodySmall?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ]);
    }

    return widgets;
  }

  String? _formatLocationLine(Property property) {
    final segments = <String>[];
    if (property.locality != null && property.locality!.isNotEmpty) {
      segments.add(property.locality!);
    }
    if (property.city.isNotEmpty) {
      segments.add(property.city);
    }
    if (segments.isEmpty && property.state != null && property.state!.isNotEmpty) {
      segments.add(property.state!);
    }
    if (segments.isEmpty && property.country.isNotEmpty) {
      segments.add(property.country);
    }
    if (segments.isEmpty) {
      return null;
    }
    return segments.join(', ');
  }

  String _formatFeatureSummary(Property property) {
    final bedrooms = property.bedrooms;
    if (bedrooms == null || bedrooms <= 0) {
      return '';
    }
    return '${bedrooms} BHK';
  }

  String _formatDistance(double distanceKm) {
    final display = distanceKm >= 100
        ? distanceKm.toStringAsFixed(0)
        : distanceKm >= 10
            ? distanceKm.toStringAsFixed(0)
            : distanceKm.toStringAsFixed(1);
    return '$display km away';
  }
}
