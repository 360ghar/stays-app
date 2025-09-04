import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controllers/auth/phone_auth_controller.dart';
import '../routes/app_routes.dart';
import '../data/services/storage_service.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // First check if PhoneAuthController exists
      if (Get.isRegistered<PhoneAuthController>()) {
        final auth = Get.find<PhoneAuthController>();
        if (!auth.isAuthenticated.value) {
          return const RouteSettings(name: Routes.login);
        }
        return null;
      }
      
      // If controller doesn't exist, check storage directly for token
      final storage = Get.find<StorageService>();
      final hasToken = storage.hasAccessToken();
      
      if (!hasToken) {
        return const RouteSettings(name: Routes.login);
      }
      
      // Token exists, allow navigation (controller will be created by binding)
      return null;
    } catch (e) {
      // If any error occurs, redirect to login
      return const RouteSettings(name: Routes.login);
    }
  }
}

