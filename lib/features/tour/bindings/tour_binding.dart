import 'package:get/get.dart';

import 'package:stays_app/features/tour/controllers/tour_controller.dart';

class TourBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TourController>(() => TourController());
  }
}
