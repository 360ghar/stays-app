import 'package:get/get.dart';

import '../controllers/booking/booking_controller.dart';
import '../data/repositories/booking_repository.dart';
import '../data/providers/bookings_provider.dart';

class BookingBinding extends Bindings {
  @override
  void dependencies() {
    final bookingsProvider = Get.isRegistered<BookingsProvider>()
        ? Get.find<BookingsProvider>()
        : Get.put(BookingsProvider(), permanent: true);

    final bookingRepository = Get.isRegistered<BookingRepository>()
        ? Get.find<BookingRepository>()
        : Get.put(
            BookingRepository(provider: bookingsProvider),
            permanent: true,
          );

    if (!Get.isRegistered<BookingController>()) {
      Get.put<BookingController>(
        BookingController(repository: bookingRepository),
      );
    }
  }
}
