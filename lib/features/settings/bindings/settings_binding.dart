import 'package:get/get.dart';

import 'package:stays_app/features/settings/controllers/settings_controller.dart';
import 'package:stays_app/features/settings/controllers/theme_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(themeController: Get.find<ThemeController>()),
    );
  }
}
