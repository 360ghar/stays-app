import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    if (auth == null || !auth.isAuthenticated.value) {
      return const RouteSettings(name: Routes.login);
    }
    return null;
  }
}

