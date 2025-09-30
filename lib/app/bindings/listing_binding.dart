import 'package:get/get.dart';

import '../controllers/listing/listing_detail_controller.dart';
import '../data/providers/properties_provider.dart';
import '../data/providers/swipes_provider.dart';
import '../data/repositories/properties_repository.dart';
import '../data/repositories/wishlist_repository.dart';

class ListingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertiesProvider>(() => PropertiesProvider());
    Get.lazyPut<PropertiesRepository>(
      () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
    );
    Get.lazyPut<SwipesProvider>(() => SwipesProvider());
    Get.put<WishlistRepository>(
      WishlistRepository(provider: Get.find<SwipesProvider>()),
      permanent: true,
    );
    Get.lazyPut<ListingDetailController>(
      () => ListingDetailController(
        repository: Get.find<PropertiesRepository>(),
      ),
    );
  }
}
