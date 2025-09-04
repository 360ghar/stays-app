import 'package:get/get.dart';

import '../controllers/auth/phone_auth_controller.dart';
import '../controllers/auth/profile_controller.dart';
import '../data/services/storage_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure the PhoneAuthController dependency is available before ProfileController.
    if (!Get.isRegistered<PhoneAuthController>()) {
      Get.lazyPut<PhoneAuthController>(
        () => PhoneAuthController(
          storageService: Get.find<StorageService>(),
        ),
      );
    }
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
