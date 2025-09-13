import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../bindings/wishlist_binding.dart';
import '../../../bindings/trips_binding.dart';
import '../../../bindings/message_binding.dart';
import '../../../controllers/messaging/hotels_map_controller.dart';
import '../../../bindings/profile_binding.dart';
import '../wishlist/wishlist_view.dart';
import '../trips/trips_view.dart';
import '../messaging/locate_view.dart';
import 'profile_view.dart';
import 'explore_view.dart';

class SimpleHomeView extends StatefulWidget {
  const SimpleHomeView({super.key});

  @override
  State<SimpleHomeView> createState() => _SimpleHomeViewState();
}

class _SimpleHomeViewState extends State<SimpleHomeView> {
  late NavigationController controller;

  @override
  void initState() {
    super.initState();
    // Get the navigation controller
    controller = Get.find<NavigationController>();

    // Initialize bindings for all tabs
    WishlistBinding().dependencies();
    TripsBinding().dependencies();
    MessageBinding().dependencies();
    ProfileBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: PageView(
        controller: controller.pageController,
        onPageChanged: (index) {
          controller.currentIndex.value = index;
          // When navigating to Locate tab (index 3), refresh precise location
          if (index == 3) {
            try {
              Get.find<HotelsMapController>().getCurrentLocation();
            } catch (_) {
              // Controller will be lazily created on first access by LocateView
            }
          }
        },
        children: [
          const ExploreView(),
          const WishlistView(),
          const TripsView(),
          const LocateView(),
          const ProfileView(),
        ],
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
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: controller.tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;
                  return Expanded(
                    child: _buildNavItem(
                      tab.icon,
                      tab.label,
                      controller.currentIndex.value == index,
                      () => controller.changeTab(index),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue.shade600 : Colors.grey.shade500,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.blue.shade600 : Colors.grey.shade500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
