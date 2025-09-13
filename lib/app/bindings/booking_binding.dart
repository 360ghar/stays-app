import 'package:get/get.dart';

import '../controllers/booking/booking_controller.dart';
import '../data/repositories/booking_repository.dart';
import '../data/providers/bookings_provider.dart';

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingsProvider>(() => BookingsProvider());
    Get.lazyPut<BookingRepository>(
      () => BookingRepository(provider: Get.find<BookingsProvider>()),
    );
    Get.lazyPut<BookingController>(
      () => BookingController(repository: Get.find<BookingRepository>()),
    );
  }
}
