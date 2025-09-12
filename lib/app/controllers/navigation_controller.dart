import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final PageController pageController = PageController();

  final List<NavigationTab> tabs = [
    NavigationTab(
      icon: Icons.explore,
      label: 'Explore',
      route: '/explore',
    ),
    NavigationTab(
      icon: Icons.favorite_outline,
      label: 'Wishlist',
      route: '/wishlist',
    ),
    NavigationTab(
      icon: Icons.luggage_outlined,
      label: 'Bookings',
      route: '/trips',
    ),
    NavigationTab(
      icon: Icons.location_on_outlined,
      label: 'Locate',
      route: '/inbox',
    ),
    NavigationTab(
      icon: Icons.person_outline,
      label: 'Profile',
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
  final String label;
  final String route;

  NavigationTab({
    required this.icon,
    required this.label,
    required this.route,
  });
}