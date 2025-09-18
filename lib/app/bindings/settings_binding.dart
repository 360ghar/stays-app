import 'package:get/get.dart';

import '../controllers/settings/settings_controller.dart';
import '../controllers/settings/theme_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(themeController: Get.find<ThemeController>()),
    );
  }
}
