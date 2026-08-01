import 'package:get/get.dart';
import 'package:stays_app/features/settings/controllers/theme_controller.dart';
import 'package:stays_app/app/data/providers/feedback_provider.dart';
import 'package:stays_app/app/data/repositories/feedback_repository.dart';
import 'package:stays_app/app/data/services/locale_service.dart';
import 'package:stays_app/features/profile/controllers/about_controller.dart';
import 'package:stays_app/features/profile/controllers/edit_profile_controller.dart';
import 'package:stays_app/features/profile/controllers/feedback_controller.dart';
import 'package:stays_app/features/profile/controllers/help_controller.dart';
import 'package:stays_app/features/profile/controllers/notifications_controller.dart';
import 'package:stays_app/features/profile/controllers/preferences_controller.dart';
import 'package:stays_app/features/profile/controllers/privacy_controller.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // The auth graph + shared ProfileRepository are registered ONCE in
    // InitialBinding (R7 DI consolidation); resolve them via Get.find for the
    // feature-scoped controllers below.

    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(
        () => ProfileController(
          profileRepository: Get.find(),
          authController: Get.find(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<EditProfileController>()) {
      Get.lazyPut<EditProfileController>(
        () => EditProfileController(
          profileRepository: Get.find(),
          profileController: Get.find<ProfileController>(),
          authController: Get.find(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<PreferencesController>()) {
      final themeController = Get.find<ThemeController>();
      final localeService = Get.find<LocaleService>();
      Get.lazyPut<PreferencesController>(
        () => PreferencesController(
          profileRepository: Get.find(),
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
          profileRepository: Get.find(),
          profileController: Get.find<ProfileController>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<PrivacyController>()) {
      Get.lazyPut<PrivacyController>(
        () => PrivacyController(
          profileRepository: Get.find(),
          profileController: Get.find<ProfileController>(),
          authRepository: Get.find(),
          authController: Get.find(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FeedbackProvider>()) {
      Get.lazyPut<FeedbackProvider>(() => FeedbackProvider(), fenix: true);
    }

    if (!Get.isRegistered<FeedbackRepository>()) {
      Get.lazyPut<FeedbackRepository>(
        () => FeedbackRepository(provider: Get.find<FeedbackProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FeedbackController>()) {
      Get.lazyPut<FeedbackController>(
        () => FeedbackController(
          feedbackRepository: Get.find<FeedbackRepository>(),
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
