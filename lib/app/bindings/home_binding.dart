import 'package:get/get.dart';

import '../controllers/auth/auth_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../controllers/explore_controller.dart';
import '../controllers/listing/listing_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/filter_controller.dart';
import '../data/providers/properties_provider.dart';
import '../data/repositories/properties_repository.dart';
import '../data/providers/swipes_provider.dart';
import '../data/repositories/wishlist_repository.dart';
import '../data/providers/users_provider.dart';
import '../data/repositories/profile_repository.dart';
import '../data/services/location_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure AuthController is available for home/profile flows
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(AuthRepository(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authRepository: Get.find<AuthRepository>()),
        permanent: true,
      );
    }

    // Location service
    Get.lazyPut<LocationService>(() => LocationService(), fenix: true);

    // Navigation controller
    Get.lazyPut<NavigationController>(() => NavigationController());

    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    // REMOVE THE OLD SERVICE REGISTRATIONS. They are now permanent
    // and initialized at startup in SplashController.
    // The services are already registered as permanent with proper initialization

    // Explore controller
    Get.lazyPut<ExploreController>(() => ExploreController());

    // New Providers + Repositories
    Get.lazyPut<PropertiesProvider>(() => PropertiesProvider());
    Get.lazyPut<PropertiesRepository>(
      () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
    );
    Get.lazyPut<SwipesProvider>(() => SwipesProvider());
    Get.lazyPut<WishlistRepository>(
      () => WishlistRepository(provider: Get.find<SwipesProvider>()),
    );
    Get.lazyPut<UsersProvider>(() => UsersProvider());
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(provider: Get.find<UsersProvider>()),
    );

    Get.lazyPut<ListingController>(
      () => ListingController(repository: Get.find<PropertiesRepository>()),
    );
  }
}
