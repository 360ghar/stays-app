import 'package:get/get.dart';
import 'package:stays_app/app/controllers/auth/auth_controller.dart';
import 'package:stays_app/app/controllers/settings/theme_controller.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/services/locale_service.dart';
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
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(AuthRepository(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authRepository: Get.find<AuthRepository>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<UsersProvider>()) {
      Get.lazyPut<UsersProvider>(() => UsersProvider(), fenix: true);
    }

    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(provider: Get.find<UsersProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(
        () => ProfileController(
          profileRepository: Get.find<ProfileRepository>(),
          authController: Get.find<AuthController>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<EditProfileController>()) {
      Get.lazyPut<EditProfileController>(
        () => EditProfileController(
          profileRepository: Get.find<ProfileRepository>(),
          profileController: Get.find<ProfileController>(),
          authController: Get.find<AuthController>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<PreferencesController>()) {
      Get.lazyPut<PreferencesController>(
        () => PreferencesController(
          profileRepository: Get.find<ProfileRepository>(),
          profileController: Get.find<ProfileController>(),
          themeController: Get.find<ThemeController>(),
          localeService: Get.find<LocaleService>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<NotificationsController>()) {
      Get.lazyPut<NotificationsController>(
        () => NotificationsController(
          profileRepository: Get.find<ProfileRepository>(),
          profileController: Get.find<ProfileController>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<PrivacyController>()) {
      Get.lazyPut<PrivacyController>(
        () => PrivacyController(
          profileRepository: Get.find<ProfileRepository>(),
          profileController: Get.find<ProfileController>(),
          authRepository: Get.find<AuthRepository>(),
          authController: Get.find<AuthController>(),
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
