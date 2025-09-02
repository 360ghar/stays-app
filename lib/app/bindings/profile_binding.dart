import 'package:get/get.dart';

import '../controllers/auth/profile_controller.dart';
import '../controllers/auth/auth_controller.dart';
import '../data/providers/auth_provider.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/storage_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthController available for logout/profile actions
    if (!Get.isRegistered<AuthProvider>()) {
      Get.lazyPut<AuthProvider>(() => AuthProvider());
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(provider: Get.find<AuthProvider>()));
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController(
            authRepository: Get.find<AuthRepository>(),
            storageService: Get.find<StorageService>(),
          ));
    }
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
