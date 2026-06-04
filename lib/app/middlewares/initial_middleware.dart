import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class InitialMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Don't redirect immediately - let SplashView handle navigation
    return null;
  }
}
