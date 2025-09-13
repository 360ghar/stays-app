import 'package:get/get.dart';

import '../controllers/listing/listing_detail_controller.dart';
import '../data/providers/properties_provider.dart';
import '../data/repositories/properties_repository.dart';

class ListingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PropertiesProvider>()) {
      Get.put<PropertiesProvider>(PropertiesProvider());
    }
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.put<PropertiesRepository>(
        PropertiesRepository(provider: Get.find<PropertiesProvider>()),
      );
    }
    Get.lazyPut<ListingDetailController>(
      () =>
          ListingDetailController(repository: Get.find<PropertiesRepository>()),
    );
  }
}
