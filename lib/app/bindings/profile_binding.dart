import 'package:get/get.dart';

import '../controllers/auth/profile_controller.dart';
import '../controllers/auth/auth_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/providers/users_provider.dart';
import '../data/repositories/profile_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthController is available when navigating directly to profile
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(AuthRepository(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authRepository: Get.find<AuthRepository>()),
        permanent: true,
      );
    }
    Get.lazyPut<UsersProvider>(() => UsersProvider());
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(provider: Get.find<UsersProvider>()),
    );
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
