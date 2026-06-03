import 'package:get/get.dart';

import 'package:stays_app/features/messaging/bindings/message_binding.dart';
import 'package:stays_app/features/trips/bindings/trips_binding.dart';
import 'package:stays_app/features/wishlist/bindings/wishlist_binding.dart';
import 'package:stays_app/features/profile/bindings/profile_binding.dart'
    as profile_binding;
import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/explore/controllers/explore_controller.dart';
import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/features/listing/controllers/location_search_controller.dart';
import 'package:stays_app/features/listing/controllers/listing_controller.dart';
import 'package:stays_app/features/home/controllers/navigation_controller.dart';
import 'package:stays_app/app/data/providers/properties_provider.dart';
import 'package:stays_app/app/data/providers/swipes_provider.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';
import 'package:stays_app/app/data/providers/supabase_auth_provider.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/utils/services/token_service.dart';

/// HomeBinding registers all dependencies needed for the home shell view.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<IAuthProvider>()) {
      Get.put<IAuthProvider>(SupabaseAuthProvider(), permanent: true);
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(
        AuthRepository(provider: Get.find<IAuthProvider>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(
          authRepository: Get.find<AuthRepository>(),
          tokenService: Get.find<TokenService>(),
        ),
        permanent: true,
      );
    }

    // ============================================
    // PROVIDERS (must come before repositories)
    // ============================================
    if (!Get.isRegistered<PropertiesProvider>()) {
      Get.lazyPut<PropertiesProvider>(() => PropertiesProvider(), fenix: true);
    }

    if (!Get.isRegistered<SwipesProvider>()) {
      Get.lazyPut<SwipesProvider>(() => SwipesProvider(), fenix: true);
    }

    if (!Get.isRegistered<UsersProvider>()) {
      Get.lazyPut<UsersProvider>(() => UsersProvider(), fenix: true);
    }

    // ============================================
    // REPOSITORIES (must come before controllers)
    // ============================================
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(
        () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<WishlistRepository>()) {
      Get.lazyPut<WishlistRepository>(
        () => WishlistRepository(provider: Get.find<SwipesProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(provider: Get.find<UsersProvider>()),
        fenix: true,
      );
    }

    // ============================================
    // SERVICES & CONTROLLERS
    // ============================================
    if (!Get.isRegistered<LocationService>()) {
      Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
    }

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
          locationService: Get.find<LocationService>(),
          propertiesRepository: Get.find<PropertiesRepository>(),
          wishlistRepository: Get.find<WishlistRepository>(),
          filterController: Get.find<FilterController>(),
          favoritesController: Get.find<FavoritesController>(),
        ),
        fenix: true,
      );
    }

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

    WishlistBinding().dependencies();
    TripsBinding().dependencies();
    MessageBinding().dependencies();
    profile_binding.ProfileBinding().dependencies();
  }
}
