import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../controllers/auth/otp_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/storage_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository());
    Get.lazyPut<AuthController>(() => AuthController(
          authRepository: Get.find<AuthRepository>(),
          storageService: Get.find<StorageService>(),
        ));
    Get.lazyPut<OTPController>(() => OTPController());
  }
}
