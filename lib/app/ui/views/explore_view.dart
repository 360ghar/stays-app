import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/explore_controller.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/ui/widgets/cards/property_card.dart';
import 'package:stays_app/app/ui/widgets/common/filter_button.dart';
import 'package:stays_app/app/ui/widgets/common/section_header.dart';
import 'package:stays_app/app/ui/widgets/common/search_bar_widget.dart';
import '../theme/theme_extensions.dart';

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshLocation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(context),
              _buildActiveFilters(context),
              _buildPopularHomes(context),
              _buildNearbyHotels(context),
              _buildRecommendedSection(context),
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
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: colors.surface,
      elevation: 0,
      toolbarHeight: 70,
      titleSpacing: 16,
      automaticallyImplyLeading: false,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SearchBarWidget(
              placeholder: 'Search',
              onTap: controller.navigateToSearch,
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
        if (tags.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
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
                child: const Text('Clear'),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPopularHomes(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final city = controller.locationName;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Column(
            key: ValueKey('popular-$city'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Popular stays near $city',
                onViewAll: () => controller.navigateToAllProperties(city),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: controller.isLoading.value
                    ? _buildShimmerList()
                    : _buildHotelsList(
                        context,
                        controller.popularHomes,
                        'popular',
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNearbyHotels(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final nearbyCity = controller.locationName;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Column(
            key: ValueKey('nearby-$nearbyCity'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Popular hotels near $nearbyCity',
                onViewAll: () => controller.navigateToAllProperties(nearbyCity),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: controller.isLoading.value
                    ? _buildShimmerList()
                    : _buildHotelsList(
                        context,
                        controller.nearbyHotels,
                        'nearby',
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRecommendedSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.recommendedHotels.isEmpty) return const SizedBox();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const SectionHeader(title: 'Recommended for you'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: controller.isLoading.value
                    ? _buildShimmerList()
                    : _buildHotelsList(
                        context,
                        controller.recommendedHotels,
                        'recommended',
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHotelsList(
    BuildContext context,
    List hotels,
    String heroPrefix,
  ) {
    if (hotels.isEmpty) {
      final colors = Theme.of(Get.context ?? context).colorScheme;
      final textStyles = Theme.of(Get.context ?? context).textTheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hotel_outlined,
                size: 48,
                color: colors.outline.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                'No hotels available',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: hotels.length,
      itemBuilder: (context, index) {
        final hotel = hotels[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: PropertyCard(
                  property: hotel,
                  heroPrefix: '${heroPrefix}_$index',
                  isFavorite: controller.isPropertyFavorite(hotel.id),
                  onTap: () => controller.navigateToPropertyDetail(hotel),
                  onFavoriteToggle: () => controller.toggleFavorite(hotel),
                ),
              ),
            );
          },
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
      itemBuilder: (context, index) {
        return const PropertyCardShimmer();
      },
    );
  }
}
