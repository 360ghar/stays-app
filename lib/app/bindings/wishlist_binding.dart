import 'package:get/get.dart';
import '../controllers/wishlist_controller.dart';
import '../data/providers/swipes_provider.dart';
import '../data/repositories/wishlist_repository.dart';
import '../controllers/filter_controller.dart';

class WishlistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SwipesProvider>(() => SwipesProvider());
    Get.lazyPut<WishlistRepository>(
      () => WishlistRepository(provider: Get.find<SwipesProvider>()),
    );
    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }
    Get.lazyPut<WishlistController>(() => WishlistController());
  }
}
