import 'package:get/get.dart';

import 'package:stays_app/features/listing/controllers/listing_detail_controller.dart';

class ListingBinding extends Bindings {
  @override
  void dependencies() {
    // PropertiesProvider/Repository, SwipesProvider and WishlistRepository are
    // registered ONCE in InitialBinding (R7 DI consolidation); only the
    // feature-scoped controller is registered here.
    if (!Get.isRegistered<ListingDetailController>()) {
      Get.lazyPut<ListingDetailController>(
        () => ListingDetailController(repository: Get.find()),
      );
    }
  }
}
