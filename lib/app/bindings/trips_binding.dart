import 'package:get/get.dart';
import '../controllers/trips_controller.dart';
import '../data/providers/bookings_provider.dart';
import '../data/repositories/booking_repository.dart';
import '../controllers/filter_controller.dart';

class TripsBinding extends Bindings {
  @override
  void dependencies() {
    final bookingsProvider =
        Get.isRegistered<BookingsProvider>()
            ? Get.find<BookingsProvider>()
            : Get.put(BookingsProvider(), permanent: true);

    final bookingRepository =
        Get.isRegistered<BookingRepository>()
            ? Get.find<BookingRepository>()
            : Get.put(
              BookingRepository(provider: bookingsProvider),
              permanent: true,
            );

    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    if (!Get.isRegistered<TripsController>()) {
      Get.lazyPut<TripsController>(() => TripsController(), fenix: true);
    }
    if (Get.isRegistered<TripsController>()) {
      Get.find<TripsController>();
    }
  }
}
