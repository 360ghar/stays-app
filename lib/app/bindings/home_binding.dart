import 'package:get/get.dart';

import '../controllers/listing/listing_controller.dart';
import '../data/providers/listing_provider.dart';
import '../data/repositories/listing_repository.dart';
import '../data/services/storage_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListingProvider>(() => ListingProvider());
    Get.lazyPut<ListingRepository>(() => ListingRepository(
          provider: Get.find<ListingProvider>(),
          storage: Get.find<StorageService>(),
        ));
    Get.lazyPut<ListingController>(() => ListingController(repository: Get.find<ListingRepository>()));
  }
}
