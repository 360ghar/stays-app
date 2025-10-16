import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/messaging/hotels_map_controller.dart';
import '../../../controllers/navigation_controller.dart';
import '../messaging/locate_view.dart';
import '../bookings/bookings_page.dart';
import '../wishlist/wishlist_view.dart';
import 'explore_view.dart';
import 'profile_view.dart';

class SimpleHomeView extends StatefulWidget {
  const SimpleHomeView({super.key});

  @override
  State<SimpleHomeView> createState() => _SimpleHomeViewState();
}

class _SimpleHomeViewState extends State<SimpleHomeView> {
  late final NavigationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NavigationController>();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shadowColor =
        theme.brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.05);
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: PageView(
        controller: controller.pageController,
        onPageChanged: (index) {
          controller.currentIndex.value = index;
          if (index == 3 && Get.isRegistered<HotelsMapController>()) {
            Get.find<HotelsMapController>().getCurrentLocation();
          }
        },
        children: [
          const ExploreView(),
          const WishlistView(),
          BookingsPage(),
          const LocateView(),
          const ProfileView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
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
                children:
                    controller.tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final isActive = controller.currentIndex.value == index;
                      return Expanded(
                        child: _NavItem(
                          icon: tab.icon,
                          labelKey: tab.labelKey,
                          isActive: isActive,
                          onTap: () => controller.changeTab(index),
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
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.labelKey,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String labelKey;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? activeColor : inactiveColor, size: 22),
            const SizedBox(height: 2),
            Text(
              labelKey.tr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
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
