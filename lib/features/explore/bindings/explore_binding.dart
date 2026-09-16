import 'package:get/get.dart';
import 'package:stays_app/features/explore/controllers/explore_controller.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    // LocationService, PropertiesProvider/Repository, SwipesProvider and
    // WishlistRepository are registered ONCE in InitialBinding (R7 DI
    // consolidation); resolve them via Get.find below.

    // Register FilterController as permanent singleton
    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    // Register FavoritesController as permanent singleton BEFORE ExploreController
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put<FavoritesController>(FavoritesController(), permanent: true);
    }

    // Register ExploreController AFTER all dependencies are registered
    Get.lazyPut<ExploreController>(
      () => ExploreController(
        locationService: Get.find(),
        propertiesRepository: Get.find(),
        wishlistRepository: Get.find(),
        filterController: Get.find<FilterController>(),
        favoritesController: Get.find<FavoritesController>(),
      ),
    );
  }
}
