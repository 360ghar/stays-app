import 'package:get/get.dart';

import '../controllers/booking/booking_controller.dart';
import '../data/providers/booking_provider.dart';
import '../data/repositories/booking_repository.dart';

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingProvider>(() => BookingProvider());
    Get.lazyPut<BookingRepository>(() => BookingRepository(provider: Get.find<BookingProvider>()));
    Get.lazyPut<BookingController>(() => BookingController(repository: Get.find<BookingRepository>()));
  }
}

