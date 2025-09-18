import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  // Default to the Home/Explore tab (index 0)
  final RxInt currentIndex = 0.obs;
  final PageController pageController = PageController(initialPage: 0);

  final List<NavigationTab> tabs = [
    NavigationTab(icon: Icons.explore, labelKey: 'nav.explore', route: '/explore'),
    NavigationTab(
      icon: Icons.favorite_outline,
      labelKey: 'nav.wishlist',
      route: '/wishlist',
    ),
    NavigationTab(
      icon: Icons.luggage_outlined,
      labelKey: 'nav.bookings',
      route: '/trips',
    ),
    NavigationTab(
      icon: Icons.location_on_outlined,
      labelKey: 'nav.locate',
      route: '/inbox',
    ),
    NavigationTab(
      icon: Icons.person_outline,
      labelKey: 'nav.profile',
      route: '/profile',
    ),
  ];

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void changeTab(int index) {
    if (index != currentIndex.value) {
      currentIndex.value = index;
      pageController.jumpToPage(index);
    }
  }

  void navigateToTab(int index) {
    changeTab(index);
  }

  String get currentRoute => tabs[currentIndex.value].route;
}

class NavigationTab {
  final IconData icon;
  final String labelKey;
  final String route;

  NavigationTab({required this.icon, required this.labelKey, required this.route});
}
