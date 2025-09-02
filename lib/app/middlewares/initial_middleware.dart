import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../routes/app_routes.dart';

class InitialMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authReady = Get.isRegistered<AuthController>();
    if (!authReady) return null;
    final auth = Get.find<AuthController>();
    if (auth.isAuthenticated.value) {
      return const RouteSettings(name: Routes.home);
    }
    return const RouteSettings(name: Routes.login);
  }
}

