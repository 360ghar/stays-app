import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/explore_controller.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/ui/widgets/cards/property_card.dart';
import 'package:stays_app/app/ui/widgets/common/banner_carousel.dart';
import 'package:stays_app/app/ui/widgets/common/filter_button.dart';
import 'package:stays_app/app/ui/widgets/common/search_bar_widget.dart';
import 'package:stays_app/app/ui/widgets/common/section_header.dart';

import '../../theme/theme_extensions.dart';

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
              _buildBannerSection(),
              _buildPopularHomes(),
              _buildNearbyHotels(),
              _buildRecommendedSection(),
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
      toolbarHeight: 70,
      titleSpacing: 16,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SearchBarWidget(
              placeholder: 'explore.search_placeholder'.tr,
              onTap: controller.navigateToSearch,
              trailing: TextButton.icon(
                onPressed: controller.useMyLocation,
                icon: Icon(Icons.my_location, size: 18, color: colors.primary),
                label: Text('explore.use_my_location'.tr),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  foregroundColor: colors.primary,
                  textStyle: textStyles.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              margin: EdgeInsets.zero,
              height: 52,
              borderRadius: BorderRadius.circular(18),
              shadowColor: colors.shadow.withValues(alpha: 0.08),
              backgroundColor: colors.surface,
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => FilterButton(
              isActive: filtersRx.value.isNotEmpty,
              onPressed:
                  () => filterController.openFilterSheet(
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
                  children:
                      tags
                          .map(
                            (tag) => Chip(
                              label: Text(
                                tag,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                ),
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
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1551776235-dde6d4829808?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1541427468627-a89a96e5ca0c?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?q=80&w=1600&auto=format&fit=crop',
    ];

    return const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: BannerCarousel(imageUrls: bannerUrls, aspectRatio: 16 / 6),
      ),
    );
  }

  Widget _buildPopularHomes() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final city = controller.locationName;
        final isLoading = controller.isLoading.value;
        final properties = controller.popularHomes;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey('popular-$city'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              SectionHeader(
                title: 'explore.popular_stays'.trParams({'city': city}),
                onViewAll: () => controller.navigateToAllProperties(city),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child:
                    isLoading
                        ? _buildShimmerList()
                        : _buildHotelsList(properties, 'popular'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNearbyHotels() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final nearbyCity = controller.locationName;
        final isLoading = controller.isLoading.value;
        final properties = controller.nearbyHotels;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            key: ValueKey('nearby-$nearbyCity'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              SectionHeader(
                title: 'explore.popular_hotels'.trParams({'city': nearbyCity}),
                onViewAll: () => controller.navigateToAllProperties(nearbyCity),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child:
                    isLoading
                        ? _buildShimmerList()
                        : _buildHotelsList(properties, 'nearby'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRecommendedSection() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final recommendations = controller.recommendedHotels;
        if (recommendations.isEmpty) {
          return const SizedBox.shrink();
        }
        final isLoading = controller.isLoading.value;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              SectionHeader(title: 'explore.recommended'.tr),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child:
                    isLoading
                        ? _buildShimmerList()
                        : _buildHotelsList(recommendations, 'recommended'),
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
            onFavoriteToggle: () => controller.toggleFavorite(property),
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
