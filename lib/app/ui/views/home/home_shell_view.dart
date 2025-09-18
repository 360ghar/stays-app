import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../bindings/home_binding.dart';
import '../../../bindings/message_binding.dart';
import '../../../bindings/profile_binding.dart';
import '../../../bindings/trips_binding.dart';
import '../../../controllers/auth/auth_controller.dart';
import '../../../controllers/navigation_controller.dart';
import '../../views/home/simple_home_view.dart';

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  @override
  void initState() {
    super.initState();
    // Ensure required bindings are ready for tabs
    HomeBinding().dependencies();
    MessageBinding().dependencies();
    ProfileBinding().dependencies();
    TripsBinding().dependencies();

    final args = Get.arguments;
    final tabIndex = args is Map<String, dynamic>
        ? args['tabIndex'] as int?
        : null;
    if (tabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          Get.find<NavigationController>().changeTab(tabIndex);
        } catch (_) {}
      });
    }

    // Ensure auth state is hydrated via AuthController
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();
      if (!authController.isAuthenticated.value) {
        authController.onInit();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SimpleHomeView();
  }
}
