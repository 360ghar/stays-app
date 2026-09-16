import 'package:get/get.dart';

import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/features/trips/controllers/trips_controller.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/app/data/providers/review_provider.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/data/repositories/review_repository.dart';

class TripsBinding extends Bindings {
  @override
  void dependencies() {
    // PropertiesProvider/Repository are registered ONCE in InitialBinding
    // (R7 DI consolidation); only trips-scoped deps live here.

    final bookingsProvider = Get.isRegistered<BookingsProvider>()
        ? Get.find<BookingsProvider>()
        : Get.put(BookingsProvider(), permanent: true);

    if (!Get.isRegistered<BookingRepository>()) {
      Get.put<BookingRepository>(
        BookingRepository(provider: bookingsProvider),
        permanent: true,
      );
    }

    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    // Review repository for the leave-review flow.
    if (!Get.isRegistered<ReviewProvider>()) {
      Get.lazyPut<ReviewProvider>(() => ReviewProvider(), fenix: true);
    }
    if (!Get.isRegistered<ReviewRepository>()) {
      Get.lazyPut<ReviewRepository>(
        () => ReviewRepository(provider: Get.find<ReviewProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<TripsController>()) {
      Get.put<TripsController>(TripsController(), permanent: true);
    }
  }
}
