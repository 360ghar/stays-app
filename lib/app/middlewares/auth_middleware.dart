import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../routes/app_routes.dart';
import '../utils/logger/app_logger.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authController = Get.find<AuthController>();
      if (authController.isAuthenticated.value) {
        return null;
      } else {
        AppLogger.info('AuthMiddleware: User not authenticated. Redirecting to login.');
        return const RouteSettings(name: Routes.login);
      }
    } catch (e) {
      AppLogger.error('Auth middleware error: $e. Redirecting to login as fallback.', e);
      return const RouteSettings(name: Routes.login);
    }
  }
  
  @override
  GetPage? onPageCalled(GetPage? page) {
    // Additional security check
    AppLogger.debug('Auth middleware called for route: ${page?.name}');
    return super.onPageCalled(page);
  }
}

