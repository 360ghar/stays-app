import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/explore_controller.dart';
import 'package:stays_app/app/ui/widgets/cards/property_card.dart';
import 'package:stays_app/app/ui/widgets/common/section_header.dart';
import 'package:stays_app/app/ui/widgets/common/search_bar_widget.dart';
import 'package:stays_app/app/ui/widgets/common/banner_carousel.dart';

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(context),
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
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: const Color(0xFFF8F9FA),
      elevation: 0,
      toolbarHeight: 70,
      flexibleSpace: FlexibleSpaceBar(
        background: SearchBarWidget(
          placeholder: 'Start your search',
          onTap: controller.navigateToSearch,
          trailing: TextButton.icon(
            onPressed: controller.useMyLocation,
            icon: const Icon(Icons.my_location, size: 18),
            label: const Text('Use my location'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              foregroundColor: Colors.blue[700],
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Banners carousel section (hardcoded URLs for now)
  Widget _buildBannerSection() {
    const bannerUrls = <String>[
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1551776235-dde6d4829808?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1541427468627-a89a96e5ca0c?q=80&w=1600&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?q=80&w=1600&auto=format&fit=crop',
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: BannerCarousel(imageUrls: bannerUrls, aspectRatio: 16 / 6),
      ),
    );
  }

  Widget _buildPopularHomes() {
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
                    : _buildHotelsList(controller.popularHomes, 'popular'),
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
                    : _buildHotelsList(controller.nearbyHotels, 'nearby'),
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

  Widget _buildHotelsList(List hotels, String heroPrefix) {
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
                'No hotels available',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
