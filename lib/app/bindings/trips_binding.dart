import 'package:get/get.dart';
import '../controllers/trips_controller.dart';
import '../data/providers/bookings_provider.dart';
import '../data/repositories/booking_repository.dart';
import '../controllers/filter_controller.dart';

class TripsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingsProvider>(() => BookingsProvider());
    Get.lazyPut<BookingRepository>(
      () => BookingRepository(provider: Get.find<BookingsProvider>()),
    );
    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }
    Get.lazyPut<TripsController>(() => TripsController());
  }
}
