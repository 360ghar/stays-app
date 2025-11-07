import 'package:get/get.dart';

import '../bindings/message_binding.dart';
import '../bindings/trips_binding.dart';
import '../bindings/wishlist_binding.dart';
import '../bindings/profile_binding.dart' as profile_binding;
import '../controllers/auth/auth_controller.dart';
import '../controllers/explore_controller.dart';
import '../controllers/filter_controller.dart';
import '../controllers/listing/location_search_controller.dart';
import '../controllers/listing/listing_controller.dart';
import '../controllers/navigation_controller.dart';
import '../data/providers/properties_provider.dart';
import '../data/providers/swipes_provider.dart';
import '../data/providers/users_provider.dart';
import '../data/repositories/auth_repository.dart';
import '../data/providers/auth/i_auth_provider.dart';
import '../data/providers/supabase_auth_provider.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/properties_repository.dart';
import '../data/repositories/wishlist_repository.dart';
import '../data/services/location_service.dart';

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
        AuthController(authRepository: Get.find<AuthRepository>()),
        permanent: true,
      );
    }

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

    if (!Get.isRegistered<ExploreController>()) {
      Get.lazyPut<ExploreController>(() => ExploreController(), fenix: true);
    }

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

    if (!Get.isRegistered<UsersProvider>()) {
      Get.lazyPut<UsersProvider>(() => UsersProvider(), fenix: true);
    }

    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(provider: Get.find<UsersProvider>()),
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
