import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../bindings/home_binding.dart';
import '../../../bindings/message_binding.dart';
import '../../../bindings/profile_binding.dart';
import '../../../controllers/auth/phone_auth_controller.dart';
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
    
    // Ensure PhoneAuthController is initialized and check auth status
    if (Get.isRegistered<PhoneAuthController>()) {
      final authController = Get.find<PhoneAuthController>();
      // Trigger auth check if not already authenticated
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
