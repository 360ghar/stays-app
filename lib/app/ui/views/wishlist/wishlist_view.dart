import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/ui/widgets/common/filter_button.dart';

import '../../../controllers/wishlist_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../routes/app_routes.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/cards/property_grid_card.dart';

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
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'Wishlist',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() {
            final isActive = filtersRx.value.isNotEmpty;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SizedBox(
                height: 36,
                child: FilterButton(
                  isActive: isActive,
                  onPressed: () => filterController.openFilterSheet(
                    context,
                    FilterScope.wishlist,
                  ),
                ),
              ),
            );
          }),
          Obx(
            () => controller.wishlistItems.isNotEmpty
                ? IconButton(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: PropertyGridCard(
        property: item,
        onTap: () => Get.toNamed(
          Routes.listingDetail.replaceFirst(':id', item.id.toString()),
          arguments: item,
        ),
        onFavoriteToggle: () => controller.removeFromWishlist(item.id),
        isFavorite: true,
        heroPrefix: 'wishlist',
        isCompact: true,
      ),
    );
  }
}
