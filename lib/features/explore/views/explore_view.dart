import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/explore/controllers/explore_controller.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/ui/theme/app_dimensions.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';
import 'package:stays_app/app/ui/widgets/common/explore_hero_header.dart';
import 'package:stays_app/app/ui/widgets/common/filter_button.dart';
import 'package:stays_app/app/ui/widgets/common/property_horizontal_section.dart';
import 'package:stays_app/app/ui/widgets/common/search_bar_widget.dart';
import 'package:stays_app/app/ui/widgets/common/section_header.dart';
import 'package:stays_app/app/ui/widgets/cards/featured_property_card.dart';

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
              _buildHeroGreeting(context),
              _buildFeaturedSection(context),
              _buildPopularInSection(context),
              _buildNearbySection(context),
              const SliverToBoxAdapter(child: SizedBox(height: 56)),
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

  Widget _buildHeroGreeting(BuildContext context) {
    return const SliverToBoxAdapter(
      child: ExploreHeroHeader(),
    );
  }

  Widget _buildFeaturedSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final isLoading = controller.isLoading.value;
        final nearest = controller.nearestProperty;
        final errorMsg = controller.errorMessage.value;

        // Show error state for offline with no data
        if (errorMsg.isNotEmpty && nearest == null && !isLoading) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppDimensions.exploreSectionSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Featured near you',
                subtitle: 'Closest stay based on your location',
                leadingIcon: Icons.near_me_rounded,
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const FeaturedPropertyStripShimmer()
              else if (nearest != null)
                FeaturedPropertyStrip(
                  property: nearest,
                  heroPrefix: 'featured_strip',
                  isFavorite: controller.isPropertyFavorite(nearest.id),
                  onTap: () => controller.navigateToPropertyDetail(nearest),
                  onFavoriteToggle: () => controller.toggleFavorite(nearest),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPopularInSection(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(
        top: AppDimensions.exploreSectionSpacing,
      ),
      sliver: SliverToBoxAdapter(
        child: Obx(() {
          final city = controller.locationName;
          final isLoading = controller.isLoading.value;
          final properties = controller.popularInCity;
          final colors = context.colors;
          final textStyles = context.textStyles;
          final titleStyle = textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          );
          final subtitleStyle = textStyles.labelMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          );

          final locationLabel = city.isEmpty ? 'this area' : city;
          return PropertyHorizontalSection(
            title: 'Popular stay in $locationLabel',
            leadingIcon: Icons.local_fire_department_rounded,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            properties: properties,
            isLoading: isLoading && properties.isEmpty,
            sectionPrefix: 'popular',
            cardHeight: 230,
            cardWidth: 220,
            onViewAll: () => controller.navigateToAllProperties(city),
            onPropertyTap: (property) => controller.navigateToPropertyDetail(property),
            onFavoriteToggle: (property) => controller.toggleFavorite(property),
            isPropertyFavorite: (id) => controller.isPropertyFavorite(id),
            emptyMessage: 'No popular stays found in $city',
          );
        }),
      ),
    );
  }

  Widget _buildNearbySection(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(
        top: AppDimensions.exploreSectionSpacing,
      ),
      sliver: SliverToBoxAdapter(
        child: Obx(() {
          final isLoading = controller.isLoading.value;
          final properties = controller.nearbyStays;
          final city = controller.locationName;
          final colors = context.colors;
          final textStyles = context.textStyles;
          final titleStyle = textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          );
          final subtitleStyle = textStyles.labelMedium?.copyWith(
            color: colors.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          );

          // Don't show this section if there are no nearby properties
          if (properties.isEmpty && !isLoading) {
            return const SizedBox.shrink();
          }

          final locationLabel = city.isEmpty ? 'this area' : city;
          return PropertyHorizontalSection(
            title: 'Nearby stay in $locationLabel',
            leadingIcon: Icons.place_outlined,
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            properties: properties,
            isLoading: isLoading,
            sectionPrefix: 'nearby',
            cardHeight: 230,
            cardWidth: 220,
            onPropertyTap: (property) => controller.navigateToPropertyDetail(property),
            onFavoriteToggle: (property) => controller.toggleFavorite(property),
            isPropertyFavorite: (id) => controller.isPropertyFavorite(id),
            emptyMessage: 'No nearby stays found',
          );
        }),
      ),
    );
  }
}
