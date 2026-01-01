import 'package:get/get.dart';

import 'package:stays_app/app/data/services/app_update_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Controller for the force update screen.
///
/// Handles opening the app store when user taps "Update Now".
class ForceUpdateController extends GetxController {
  late final AppUpdateService _updateService;

  final RxBool isLoading = false.obs;

  /// Current app version
  String get currentVersion => _updateService.currentVersion;

  /// Minimum required version
  String get requiredVersion => _updateService.minAppVersion.value;

  /// Store version available
  String get storeVersion => _updateService.storeVersion.value;

  /// Release notes
  String get releaseNotes => _updateService.releaseNotes.value;

  @override
  void onInit() {
    super.onInit();
    _updateService = Get.find<AppUpdateService>();
  }

  /// Open the app store
  Future<void> openStore() async {
    isLoading.value = true;

    try {
      final success = await _updateService.openStore();
      if (!success) {
        Get.snackbar(
          'error'.tr,
          'update.store_unavailable'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      AppLogger.error('Failed to open store', e);
      Get.snackbar(
        'error'.tr,
        'update.store_unavailable'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
