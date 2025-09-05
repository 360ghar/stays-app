import 'package:get/get.dart';

import '../controllers/auth/phone_auth_controller.dart';
import '../controllers/explore_controller.dart';
import '../controllers/listing/listing_controller.dart';
import '../controllers/navigation_controller.dart';
import '../data/providers/listing_provider.dart';
import '../data/repositories/listing_repository.dart';
import '../data/services/location_service.dart';
import '../data/services/storage_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PhoneAuthController is available
    if (!Get.isRegistered<PhoneAuthController>()) {
      Get.put<PhoneAuthController>(
        PhoneAuthController(
          storageService: Get.find<StorageService>(),
        ),
        permanent: true,
      );
    }

    // Location service
    Get.lazyPut<LocationService>(
      () => LocationService(),
      fenix: true,
    );

    // Navigation controller
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
    );

    // Explore controller
    Get.lazyPut<ExploreController>(
      () => ExploreController(),
    );
    
    Get.lazyPut<ListingProvider>(() => ListingProvider());
    Get.lazyPut<ListingRepository>(() => ListingRepository(
          provider: Get.find<ListingProvider>(),
          storage: Get.find<StorageService>(),
        ));
    Get.lazyPut<ListingController>(() => ListingController(repository: Get.find<ListingRepository>()));
  }
}
