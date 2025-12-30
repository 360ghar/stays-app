import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/helpers/haptic_helper.dart';

class NavigationController extends BaseController {
  // Default to the Home/Explore tab (index 0)
  final RxInt currentIndex = 0.obs;
  final PageController pageController = PageController(initialPage: 0);

  int? _pendingTabIndex;

  final List<NavigationTab> tabs = [
    NavigationTab(
      icon: Icons.explore,
      labelKey: 'nav.explore',
      route: '/explore',
    ),
    NavigationTab(
      icon: Icons.favorite_outline,
      labelKey: 'nav.wishlist',
      route: '/wishlist',
    ),
    NavigationTab(
      icon: Icons.luggage_outlined,
      labelKey: 'nav.enquiries',
      route: Routes.inquiries,
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

  @override
  void onReady() {
    super.onReady();
    final initialIndex = _resolveInitialTabIndex(Get.arguments);
    if (initialIndex != null) {
      changeTab(initialIndex);
    }
  }

  int? _resolveInitialTabIndex(dynamic args) {
    if (args is int) {
      return args;
    }

    if (args is Map) {
      final candidate = args['tabIndex'] ?? args['initialTabIndex'];
      if (candidate is int) {
        return candidate;
      }
      if (candidate is String) {
        return int.tryParse(candidate);
      }
    }

    return null;
  }

  void changeTab(int index) {
    if (index < 0 || index >= tabs.length) {
      return;
    }

    if (index != currentIndex.value) {
      currentIndex.value = index;
      unawaited(HapticHelper.navigation());
    }

    _pendingTabIndex = index;
    _syncPageController();
  }

  void _syncPageController() {
    if (_pendingTabIndex == null) {
      return;
    }

    if (!pageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _syncPageController(),
      );
      return;
    }

    final targetIndex = _pendingTabIndex!;
    final currentPage = pageController.page?.round();
    if (currentPage != targetIndex) {
      pageController.jumpToPage(targetIndex);
    }

    _pendingTabIndex = null;
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

  NavigationTab({
    required this.icon,
    required this.labelKey,
    required this.route,
  });
}
