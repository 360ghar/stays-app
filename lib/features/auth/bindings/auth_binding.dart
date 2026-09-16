import 'package:get/get.dart';

import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/features/auth/controllers/user_profile_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // The auth graph (IAuthProvider -> SupabaseAuthProvider, AuthApiProvider,
    // UsersProvider, ProfileRepository, GoogleSignInService,
    // AppleSignInService, FormValidationController, AuthRepository,
    // AuthController) is registered ONCE in InitialBinding (R7 DI
    // consolidation). Only auth-feature controllers live here.

    Get.lazyPut<OTPController>(() => OTPController());

    // User profile controller for profile management
    if (!Get.isRegistered<UserProfileController>()) {
      Get.lazyPut<UserProfileController>(
        () => UserProfileController(profileRepository: Get.find()),
      );
    }
  }
}
