import 'package:get/get.dart';
import 'package:stays_app/app/controllers/explore_controller.dart';
import 'package:stays_app/app/data/services/location_service.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationService>(
      () => LocationService(),
      fenix: true,
    );
    Get.lazyPut<ExploreController>(
      () => ExploreController(),
    );
  }
}