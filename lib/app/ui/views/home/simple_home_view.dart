import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/explore_controller.dart';
import 'package:stays_app/app/ui/widgets/cards/hotel_card.dart';
import 'package:stays_app/app/ui/widgets/common/section_header.dart';
import 'package:stays_app/app/ui/widgets/common/search_bar_widget.dart';
import '../../../controllers/auth/phone_auth_controller.dart';

class SimpleHomeView extends GetView<ExploreController> {
  const SimpleHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshLocation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              _buildSliverAppBar(context),
              _buildPopularHomes(),
              _buildNearbyHotels(),
              _buildRecommendedSection(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      
      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.explore, 'Explore', true),
                _buildNavItem(Icons.card_travel_outlined, 'Trips', false),
                _buildNavItem(Icons.inbox_outlined, 'Inbox', false),
                _buildNavItem(Icons.person_outline, 'Profile', false, () => Get.toNamed('/profile')),
              ],
            ),
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
        ),
      ),
    );
  }

  Widget _buildPopularHomes() {
    return SliverToBoxAdapter(
      child: Obx(() {
        final city = controller.currentCity;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Column(
            key: ValueKey('popular-$city'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Popular homes in $city',
                onViewAll: () => controller.navigateToAllHotels(city),
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
        final nearbyCity = controller.nearbyCity;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Column(
            key: ValueKey('nearby-$nearbyCity'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              SectionHeader(
                title: 'Popular hotels near $nearbyCity',
                onViewAll: () => controller.navigateToAllHotels(nearbyCity),
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
              const SectionHeader(
                title: 'Recommended for you',
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: controller.isLoading.value
                    ? _buildShimmerList()
                    : _buildHotelsList(controller.recommendedHotels, 'recommended'),
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
              Icon(
                Icons.hotel_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No hotels available',
                style: TextStyle(
                  color: Colors.grey[600],
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
                child: HotelCard(
                  hotel: hotel,
                  heroPrefix: heroPrefix,
                  onTap: () => controller.navigateToHotelDetail(hotel),
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
        return const HotelCardShimmer();
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, [VoidCallback? onTap]) {
    return InkWell(
      onTap: isActive ? null : (onTap ?? () => _showComingSoon(label)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue.shade600 : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.blue.shade600 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, PhoneAuthController authController) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.blue.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Obx(() => Text(
              authController.currentUser.value?.firstName ?? 'User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            )),
            
            const SizedBox(height: 4),
            
            Obx(() => Text(
              authController.currentUser.value?.email ?? 'No email',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            )),
            
            const SizedBox(height: 32),
            
            ListTile(
              leading: Icon(Icons.person_outline, color: Colors.grey.shade700),
              title: const Text('Edit Profile'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Edit Profile');
              },
            ),
            
            ListTile(
              leading: Icon(Icons.settings_outlined, color: Colors.grey.shade700),
              title: const Text('Settings'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Settings');
              },
            ),
            
            ListTile(
              leading: Icon(Icons.help_outline, color: Colors.grey.shade700),
              title: const Text('Help & Support'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Help & Support');
              },
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout(context, authController);
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, PhoneAuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Coming Soon',
      '$feature feature will be available soon',
      backgroundColor: Colors.blue.shade50,
      colorText: Colors.blue.shade800,
      snackPosition: SnackPosition.TOP,
      borderRadius: 8,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }
}