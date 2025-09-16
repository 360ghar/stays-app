import 'package:get/get.dart';
import 'package:stays_app/app/controllers/explore_controller.dart';
import 'package:stays_app/app/data/services/location_service.dart';
import 'package:stays_app/app/data/providers/properties_provider.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/providers/swipes_provider.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';

import '../controllers/filter_controller.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationService>(() => LocationService(), fenix: true);
    Get.lazyPut<PropertiesProvider>(() => PropertiesProvider());
    Get.lazyPut<PropertiesRepository>(
      () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
    );
    Get.lazyPut<SwipesProvider>(() => SwipesProvider());
    Get.lazyPut<WishlistRepository>(
      () => WishlistRepository(provider: Get.find<SwipesProvider>()),
    );
    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }
    Get.lazyPut<ExploreController>(() => ExploreController());
  }
}
