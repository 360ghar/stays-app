import 'package:get/get.dart';

import '../controllers/listing/listing_detail_controller.dart';
import '../data/providers/properties_provider.dart';
import '../data/providers/swipes_provider.dart';
import '../data/repositories/properties_repository.dart';
import '../data/repositories/wishlist_repository.dart';

class ListingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PropertiesProvider>()) {
      Get.lazyPut<PropertiesProvider>(() => PropertiesProvider(), fenix: true);
    }

    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(
        () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<SwipesProvider>()) {
      Get.lazyPut<SwipesProvider>(() => SwipesProvider(), fenix: true);
    }

    if (!Get.isRegistered<WishlistRepository>()) {
      Get.lazyPut<WishlistRepository>(
        () => WishlistRepository(provider: Get.find<SwipesProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ListingDetailController>()) {
      Get.lazyPut<ListingDetailController>(
        () => ListingDetailController(
          repository: Get.find<PropertiesRepository>(),
        ),
      );
    }
  }
}
