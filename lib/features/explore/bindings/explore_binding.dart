import 'package:get/get.dart';
import 'package:stays_app/features/explore/controllers/explore_controller.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/providers/properties_provider.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/providers/swipes_provider.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    // Register LocationService with fenix to persist across navigation
    if (!Get.isRegistered<LocationService>()) {
      Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
    }

    // Register PropertiesProvider
    if (!Get.isRegistered<PropertiesProvider>()) {
      Get.lazyPut<PropertiesProvider>(() => PropertiesProvider());
    }

    // Register PropertiesRepository
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(
        () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
      );
    }

    // Register SwipesProvider
    if (!Get.isRegistered<SwipesProvider>()) {
      Get.lazyPut<SwipesProvider>(() => SwipesProvider());
    }

    // Register WishlistRepository
    if (!Get.isRegistered<WishlistRepository>()) {
      Get.lazyPut<WishlistRepository>(
        () => WishlistRepository(provider: Get.find<SwipesProvider>()),
      );
    }

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
        locationService: Get.find<LocationService>(),
        propertiesRepository: Get.find<PropertiesRepository>(),
        wishlistRepository: Get.find<WishlistRepository>(),
        filterController: Get.find<FilterController>(),
        favoritesController: Get.find<FavoritesController>(),
      ),
    );
  }
}
