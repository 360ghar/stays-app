import 'package:get/get.dart';
import 'package:stays_app/app/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Use eager put to ensure onReady() runs when SplashView mounts
    Get.put<SplashController>(SplashController());
  }
}
