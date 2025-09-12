import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger/app_logger.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      // Check if AuthController exists and user is authenticated
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (!auth.isAuthenticated.value) {
          AppLogger.info('User not authenticated, redirecting to login');
          return const RouteSettings(name: Routes.login);
        }
        return null;
      }
      
      // If controller doesn't exist, check Supabase session
      final session = Supabase.instance.client.auth.currentSession;
      final hasSession = session != null && session.accessToken.isNotEmpty;
      if (!hasSession) {
        AppLogger.info('No token found, redirecting to login');
        return const RouteSettings(name: Routes.login);
      }
      
      // Token exists, allow navigation (controller will be created by binding)
      return null;
    } catch (e) {
      AppLogger.error('Auth middleware error', e);
      // If any error occurs, redirect to login
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
