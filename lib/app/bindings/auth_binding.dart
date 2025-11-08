import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../controllers/auth/otp_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/providers/auth/i_auth_provider.dart';
import '../data/providers/supabase_auth_provider.dart';
import '../controllers/auth/form_validation_controller.dart';
import '../utils/services/token_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Choose auth provider. Default to Supabase; allow future override via config.
    Get.lazyPut<IAuthProvider>(() {
      // Placeholder for switching provider via environment/config
      // For now, prefer Supabase in all flavors.
      return SupabaseAuthProvider();
    });

    Get.lazyPut<AuthRepository>(() => AuthRepository(provider: Get.find<IAuthProvider>()));

    // Form validation controller (now managed properly)
    if (!Get.isRegistered<FormValidationController>()) {
      Get.put<FormValidationController>(FormValidationController());
    }

    // Auth controller with proper dependency injection
    Get.lazyPut<AuthController>(() => AuthController(
      authRepository: Get.find<AuthRepository>(),
      tokenService: Get.find<TokenService>(),
    ));

    Get.lazyPut<OTPController>(() => OTPController());
  }
}
