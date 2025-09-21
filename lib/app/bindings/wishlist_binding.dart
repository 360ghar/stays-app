import 'package:get/get.dart';

import '../controllers/filter_controller.dart';
import '../controllers/wishlist_controller.dart';
import '../data/providers/swipes_provider.dart';
import '../data/repositories/wishlist_repository.dart';

class WishlistBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SwipesProvider>()) {
      Get.lazyPut<SwipesProvider>(() => SwipesProvider(), fenix: true);
    }
    if (!Get.isRegistered<WishlistRepository>()) {
      Get.lazyPut<WishlistRepository>(
        () => WishlistRepository(provider: Get.find<SwipesProvider>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }
    if (!Get.isRegistered<WishlistController>()) {
      Get.lazyPut<WishlistController>(() => WishlistController(), fenix: true);
    }
  }
}
