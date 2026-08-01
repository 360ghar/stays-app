import 'package:get/get.dart';

import 'package:stays_app/features/messaging/bindings/message_binding.dart';
import 'package:stays_app/features/trips/bindings/trips_binding.dart';
import 'package:stays_app/features/wishlist/bindings/wishlist_binding.dart';
import 'package:stays_app/features/profile/bindings/profile_binding.dart'
    as profile_binding;
import 'package:stays_app/features/explore/controllers/explore_controller.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/features/listing/controllers/location_search_controller.dart';
import 'package:stays_app/features/listing/controllers/listing_controller.dart';
import 'package:stays_app/features/home/controllers/navigation_controller.dart';

/// HomeBinding registers all dependencies needed for the home shell view.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // ============================================
    // SERVICES & CONTROLLERS
    // ============================================
    if (!Get.isRegistered<NavigationController>()) {
      Get.lazyPut<NavigationController>(
        () => NavigationController(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    if (!Get.isRegistered<FavoritesController>()) {
      Get.put<FavoritesController>(FavoritesController(), permanent: true);
    }

    if (!Get.isRegistered<ExploreController>()) {
      Get.lazyPut<ExploreController>(
        () => ExploreController(
          locationService: Get.find(),
          propertiesRepository: Get.find(),
          wishlistRepository: Get.find(),
          filterController: Get.find<FilterController>(),
          favoritesController: Get.find<FavoritesController>(),
        ),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ListingController>()) {
      Get.lazyPut<ListingController>(
        () => ListingController(repository: Get.find()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<LocationSearchController>()) {
      Get.lazyPut<LocationSearchController>(
        () => LocationSearchController(),
        fenix: true,
      );
    }

    WishlistBinding().dependencies();
    TripsBinding().dependencies();
    MessageBinding().dependencies();
    profile_binding.ProfileBinding().dependencies();
  }
}
