import 'package:get/get.dart';

import '../controllers/auth/phone_auth_controller.dart';
import '../controllers/listing/listing_controller.dart';
import '../data/providers/listing_provider.dart';
import '../data/repositories/listing_repository.dart';
import '../data/services/storage_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PhoneAuthController is available
    if (!Get.isRegistered<PhoneAuthController>()) {
      Get.lazyPut<PhoneAuthController>(
        () => PhoneAuthController(
          storageService: Get.find<StorageService>(),
        ),
      );
    }
    
    Get.lazyPut<ListingProvider>(() => ListingProvider());
    Get.lazyPut<ListingRepository>(() => ListingRepository(
          provider: Get.find<ListingProvider>(),
          storage: Get.find<StorageService>(),
        ));
    Get.lazyPut<ListingController>(() => ListingController(repository: Get.find<ListingRepository>()));
  }
}
