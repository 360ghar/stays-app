import 'package:get/get.dart';

import 'package:stays_app/features/inquiry/controllers/inquiry_controller.dart';
import 'package:stays_app/features/inquiry/controllers/inquiry_confirmation_controller.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/features/trips/controllers/trips_controller.dart';
import 'package:stays_app/features/trips/bindings/trips_binding.dart';
import 'package:stays_app/app/data/providers/bookings_provider.dart';

class InquiryBinding extends Bindings {
  @override
  void dependencies() {
    // The auth graph (IAuthProvider/AuthRepository/AuthController) is
    // registered ONCE in InitialBinding (R7 DI consolidation); inquiry views
    // resolve AuthController directly via Get.find when they need it.

    final bookingsProvider = Get.isRegistered<BookingsProvider>()
        ? Get.find<BookingsProvider>()
        : Get.put(BookingsProvider(), permanent: true);

    final bookingRepository = Get.isRegistered<BookingRepository>()
        ? Get.find<BookingRepository>()
        : Get.put(
            BookingRepository(provider: bookingsProvider),
            permanent: true,
          );

    if (!Get.isRegistered<InquiryController>()) {
      Get.put<InquiryController>(
        InquiryController(repository: bookingRepository),
      );
    }
    if (!Get.isRegistered<TripsController>()) {
      TripsBinding().dependencies();
    }

    if (!Get.isRegistered<InquiryConfirmationController>()) {
      Get.lazyPut<InquiryConfirmationController>(
        () => InquiryConfirmationController(),
      );
    }
  }
}
