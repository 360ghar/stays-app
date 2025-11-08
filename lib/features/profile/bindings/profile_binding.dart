import 'package:get/get.dart';
import 'package:stays_app/app/controllers/auth/auth_controller.dart';
import 'package:stays_app/app/controllers/settings/theme_controller.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';
import 'package:stays_app/app/data/providers/supabase_auth_provider.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/services/locale_service.dart';
import 'package:stays_app/app/utils/services/token_service.dart';
import 'package:stays_app/app/utils/services/validation_service.dart';
import 'package:stays_app/features/profile/controllers/about_controller.dart';
import 'package:stays_app/features/profile/controllers/edit_profile_controller.dart';
import 'package:stays_app/features/profile/controllers/help_controller.dart';
import 'package:stays_app/features/profile/controllers/notifications_controller.dart';
import 'package:stays_app/features/profile/controllers/preferences_controller.dart';
import 'package:stays_app/features/profile/controllers/privacy_controller.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IAuthProvider>()) {
      Get.put<IAuthProvider>(SupabaseAuthProvider(), permanent: true);
    }

    // Ensure core services are registered
    if (!Get.isRegistered<TokenService>()) {
      Get.put<TokenService>(TokenService(), permanent: true);
    }
    if (!Get.isRegistered<ValidationService>()) {
      Get.put<ValidationService>(ValidationService(), permanent: true);
    }

    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(
        AuthRepository(provider: Get.find<IAuthProvider>()),
        permanent: true,
      );
    }
    final authRepository = Get.find<AuthRepository>();
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          authRepository: Get.find<AuthRepository>(),
          tokenService: Get.find<TokenService>(),
        ),
        permanent: true,
      );
    }
    final authController = Get.find<AuthController>();

    if (!Get.isRegistered<UsersProvider>()) {
      Get.lazyPut<UsersProvider>(() => UsersProvider(), fenix: true);
    }

    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(provider: Get.find<UsersProvider>()),
        fenix: true,
      );
    }
    final profileRepository = Get.find<ProfileRepository>();

    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(
        () => ProfileController(
          profileRepository: profileRepository,
          authController: authController,
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<EditProfileController>()) {
      Get.lazyPut<EditProfileController>(
        () => EditProfileController(
          profileRepository: profileRepository,
          profileController: Get.find<ProfileController>(),
          authController: authController,
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<PreferencesController>()) {
      final themeController = Get.find<ThemeController>();
      final localeService = Get.find<LocaleService>();
      Get.lazyPut<PreferencesController>(
        () => PreferencesController(
          profileRepository: profileRepository,
          profileController: Get.find<ProfileController>(),
          themeController: themeController,
          localeService: localeService,
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<NotificationsController>()) {
      Get.lazyPut<NotificationsController>(
        () => NotificationsController(
          profileRepository: profileRepository,
          profileController: Get.find<ProfileController>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<PrivacyController>()) {
      Get.lazyPut<PrivacyController>(
        () => PrivacyController(
          profileRepository: profileRepository,
          profileController: Get.find<ProfileController>(),
          authRepository: authRepository,
          authController: authController,
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<HelpController>()) {
      Get.lazyPut<HelpController>(() => HelpController(), fenix: true);
    }

    if (!Get.isRegistered<AboutController>()) {
      Get.lazyPut<AboutController>(() => AboutController(), fenix: true);
    }
  }
}
