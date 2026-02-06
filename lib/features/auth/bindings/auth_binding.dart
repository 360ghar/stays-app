import 'package:get/get.dart';

import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/features/auth/controllers/form_validation_controller.dart';
import 'package:stays_app/features/auth/controllers/user_profile_controller.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';
import 'package:stays_app/app/data/providers/supabase_auth_provider.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/utils/services/token_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Choose auth provider. Default to Supabase; allow future override via config.
    Get.lazyPut<IAuthProvider>(() {
      // Placeholder for switching provider via environment/config
      // For now, prefer Supabase in all flavors.
      return SupabaseAuthProvider();
    });

    Get.lazyPut<AuthRepository>(
      () => AuthRepository(provider: Get.find<IAuthProvider>()),
    );

    if (!Get.isRegistered<UsersProvider>()) {
      Get.lazyPut<UsersProvider>(() => UsersProvider(), fenix: true);
    }

    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(provider: Get.find<UsersProvider>()),
        fenix: true,
      );
    }

    // Form validation controller (now managed properly)
    if (!Get.isRegistered<FormValidationController>()) {
      Get.put<FormValidationController>(FormValidationController());
    }

    // Auth controller with proper dependency injection
    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        tokenService: Get.find<TokenService>(),
      ),
    );

    Get.lazyPut<OTPController>(() => OTPController());

    // User profile controller for profile management
    if (!Get.isRegistered<UserProfileController>()) {
      Get.lazyPut<UserProfileController>(
        () => UserProfileController(
          profileRepository: Get.find<ProfileRepository>(),
        ),
      );
    }
  }
}
