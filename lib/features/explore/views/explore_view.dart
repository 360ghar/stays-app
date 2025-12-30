import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/explore/controllers/explore_controller.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/ui/widgets/cards/property_card.dart';
import 'package:stays_app/app/ui/widgets/common/banner_carousel.dart';
import 'package:stays_app/app/ui/widgets/common/filter_button.dart';
import 'package:stays_app/app/ui/widgets/common/search_bar_widget.dart';
import 'package:stays_app/app/ui/widgets/common/section_header.dart';

import 'package:stays_app/app/ui/theme/theme_extensions.dart';

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(context),
              _buildActiveFilters(context),
              _buildOfflineBanner(context),
              _buildBannerSection(),
              _buildPropertiesSection(context),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final filterController = Get.find<FilterController>();
    final filtersRx = filterController.rxFor(FilterScope.explore);
    final colors = context.colors;
    final textStyles = context.textStyles;
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: colors.surface,
      elevation: 0,
      toolbarHeight: 64,
      titleSpacing: 16,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SearchBarWidget(
              placeholder: 'explore.search_placeholder'.tr,
              onTap: controller.navigateToSearch,
              fontSize: 14,
              iconSize: 20,
              trailing: TextButton.icon(
                onPressed: controller.useMyLocation,
                icon: Icon(Icons.my_location, size: 16, color: colors.primary),
                label: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text('explore.use_my_location'.tr),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: colors.primary,
                  textStyle: textStyles.labelMedium?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              margin: EdgeInsets.zero,
              height: 48,
              borderRadius: BorderRadius.circular(18),
              shadowColor: colors.shadow.withValues(alpha: 0.08),
              backgroundColor: colors.surface,
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => FilterButton(
              isActive: filtersRx.value.isNotEmpty,
              onPressed: () => filterController.openFilterSheet(
                context,
                FilterScope.explore,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(BuildContext context) {
    final filterController = Get.find<FilterController>();
    final filtersRx = filterController.rxFor(FilterScope.explore);
    return SliverToBoxAdapter(
      child: Obx(() {
        final colors = Theme.of(context).colorScheme;
        final tags = filtersRx.value.activeTags();
        if (tags.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Chip(
                          label: Text(
                            tag,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colors.onPrimaryContainer),
                          ),
                          backgroundColor: colors.primaryContainer,
                        ),
                      )
                      .toList(),
                ),
              ),
              TextButton(
                onPressed: () => filterController.clear(FilterScope.explore),
                style: TextButton.styleFrom(foregroundColor: colors.primary),
                child: Text('common.clear'.tr),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBannerSection() {
    const bannerUrls = <String>[
      'https://images.unsplash.com/photo-1505691723518-36a5ac3be353?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1600&q=80',
      'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1600&q=80',
    ];

    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: BannerCarousel(imageUrls: bannerUrls, aspectRatio: 16 / 6),
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final isOffline = controller.isOffline.value;
        final isShowingCached = controller.isShowingCachedData.value;
        final errorMsg = controller.errorMessage.value;
        final colors = context.colors;
        final textStyles = context.textStyles;

        if (!isOffline && errorMsg.isEmpty) {
          return const SizedBox.shrink();
        }

        // Offline with cached data
        if (isShowingCached) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 20,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You are offline. Showing cached results.',
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Offline with no cached data - error is shown in properties section
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildPropertiesSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final city = controller.locationName;
        final isLoading = controller.isLoading.value;
        final properties = controller.allExploreProperties;
        final textStyles = context.textStyles;
        final colors = context.colors;
        final errorMsg = controller.errorMessage.value;

        // Show error state for offline with no data
        if (errorMsg.isNotEmpty && properties.isEmpty && !isLoading) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 64, color: colors.outline),
                const SizedBox(height: 16),
                Text(
                  errorMsg,
                  style: textStyles.bodyLarge?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: controller.refreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey('all-$city-${properties.length}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              SectionHeader(
                title: 'explore.popular_stays'.trParams({'city': city}),
                onViewAll: () => controller.navigateToAllProperties(city),
                titleStyle: textStyles.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: isLoading
                    ? _buildShimmerList()
                    : _buildHotelsList(properties, 'all'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHotelsList(List<Property> hotels, String heroPrefix) {
    if (hotels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'explore.no_results'.tr,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey('${heroPrefix}_list_${hotels.length}'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: hotels.length,
      itemBuilder: (context, index) {
        final property = hotels[index];
        return RepaintBoundary(
          child: PropertyCard(
            property: property,
            heroPrefix: '${heroPrefix}_$index',
            isFavorite: controller.isPropertyFavorite(property.id),
            onTap: () => controller.navigateToPropertyDetail(property),
            onFavoriteToggle: () => controller.toggleFavoriteProperty(property),
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) => const PropertyCardShimmer(),
    );
  }
}
