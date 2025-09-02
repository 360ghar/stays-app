import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../routes/app_routes.dart';

class InitialMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Don't redirect immediately - let SplashView handle navigation
    return null;
  }
}

