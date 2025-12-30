import 'package:get/get.dart';

import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/features/auth/controllers/form_validation_controller.dart';
import 'package:stays_app/features/auth/controllers/session_controller.dart';
import 'package:stays_app/features/auth/controllers/user_profile_controller.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';
import 'package:stays_app/app/data/providers/supabase_auth_provider.dart';
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

    // Form validation controller (now managed properly)
    if (!Get.isRegistered<FormValidationController>()) {
      Get.put<FormValidationController>(FormValidationController());
    }

    // User profile controller for profile management
    if (!Get.isRegistered<UserProfileController>()) {
      Get.lazyPut<UserProfileController>(() => UserProfileController());
    }

    // Session controller for token/session management
    if (!Get.isRegistered<SessionController>()) {
      Get.lazyPut<SessionController>(
        () => SessionController(tokenService: Get.find<TokenService>()),
      );
    }

    // Auth controller with proper dependency injection
    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        sessionController: Get.find<SessionController>(),
      ),
    );

    Get.lazyPut<OTPController>(() => OTPController());
  }
}
