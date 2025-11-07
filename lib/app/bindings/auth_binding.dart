import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../controllers/auth/otp_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/providers/auth/i_auth_provider.dart';
import '../data/providers/supabase_auth_provider.dart';
import '../../config/app_config.dart';
import '../controllers/auth/form_validation_controller.dart';

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
    if (!Get.isRegistered<FormValidationController>()) {
      Get.put<FormValidationController>(FormValidationController(), permanent: true);
    }
    Get.lazyPut<AuthController>(
      () => AuthController(authRepository: Get.find<AuthRepository>()),
    );
    Get.lazyPut<OTPController>(() => OTPController());
  }
}
