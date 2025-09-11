import 'package:get/get.dart';

import '../controllers/auth/profile_controller.dart';
import '../controllers/auth/auth_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/storage_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthController is available when navigating directly to profile
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(AuthRepository(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          authRepository: Get.find<AuthRepository>(),
          storageService: Get.find<StorageService>(),
        ),
        permanent: true,
      );
    }
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
