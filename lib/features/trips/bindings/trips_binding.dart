import 'package:get/get.dart';

import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/features/trips/controllers/trips_controller.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';
import 'package:stays_app/app/data/providers/properties_provider.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';

class TripsBinding extends Bindings {
  @override
  void dependencies() {
    final bookingsProvider = Get.isRegistered<BookingsProvider>()
        ? Get.find<BookingsProvider>()
        : Get.put(BookingsProvider(), permanent: true);

    if (!Get.isRegistered<BookingRepository>()) {
      Get.put<BookingRepository>(
        BookingRepository(provider: bookingsProvider),
        permanent: true,
      );
    }

    if (!Get.isRegistered<PropertiesProvider>()) {
      Get.lazyPut<PropertiesProvider>(() => PropertiesProvider(), fenix: true);
    }

    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(
        () => PropertiesRepository(provider: Get.find<PropertiesProvider>()),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    if (!Get.isRegistered<TripsController>()) {
      Get.put<TripsController>(TripsController(), permanent: true);
    }
  }
}
