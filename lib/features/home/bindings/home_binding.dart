import 'package:get/get.dart';

import 'package:stays_app/features/auth/bindings/auth_binding.dart';
import 'package:stays_app/features/explore/bindings/explore_binding.dart';
import 'package:stays_app/features/messaging/bindings/message_binding.dart';
import 'package:stays_app/features/trips/bindings/trips_binding.dart';
import 'package:stays_app/features/wishlist/bindings/wishlist_binding.dart';
import 'package:stays_app/features/profile/bindings/profile_binding.dart'
    as profile_binding;
import 'package:stays_app/features/listing/controllers/location_search_controller.dart';
import 'package:stays_app/features/listing/controllers/listing_controller.dart';
import 'package:stays_app/features/home/controllers/navigation_controller.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';

/// HomeBinding registers all dependencies needed for the home shell view.
/// It delegates to specialized bindings for each feature domain.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Delegate to specialized bindings for auth and core dependencies
    AuthBinding().dependencies();

    // Delegate to explore binding for explore-related dependencies
    ExploreBinding().dependencies();

    // Navigation controller for bottom navigation
    if (!Get.isRegistered<NavigationController>()) {
      Get.lazyPut<NavigationController>(
        () => NavigationController(),
        fenix: true,
      );
    }

    // Listing controllers
    if (!Get.isRegistered<ListingController>()) {
      Get.lazyPut<ListingController>(
        () => ListingController(repository: Get.find<PropertiesRepository>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<LocationSearchController>()) {
      Get.lazyPut<LocationSearchController>(
        () => LocationSearchController(),
        fenix: true,
      );
    }

    // Delegate to feature bindings
    WishlistBinding().dependencies();
    TripsBinding().dependencies();
    MessageBinding().dependencies();
    profile_binding.ProfileBinding().dependencies();
  }
}
