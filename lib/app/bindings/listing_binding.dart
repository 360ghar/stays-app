import 'package:get/get.dart';

import '../controllers/listing/listing_detail_controller.dart';
import '../data/providers/listing_provider.dart';
import '../data/repositories/listing_repository.dart';
import '../data/services/storage_service.dart';

class ListingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ListingProvider>()) {
      Get.put<ListingProvider>(ListingProvider());
    }
    if (!Get.isRegistered<ListingRepository>()) {
      Get.put<ListingRepository>(ListingRepository(
        provider: Get.find<ListingProvider>(),
        storage: Get.find<StorageService>(),
      ));
    }
    Get.lazyPut<ListingDetailController>(() => ListingDetailController(repository: Get.find<ListingRepository>()));
  }
}
