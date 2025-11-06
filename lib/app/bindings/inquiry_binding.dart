import 'package:get/get.dart';

import '../controllers/inquiry/inquiry_controller.dart';
import '../controllers/inquiry/inquiry_confirmation_controller.dart';
import '../data/repositories/booking_repository.dart';
import '../controllers/trips_controller.dart';
import 'trips_binding.dart';
import '../data/providers/bookings_provider.dart';
import '../controllers/auth/auth_controller.dart';
import '../data/repositories/auth_repository.dart';

class InquiryBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure auth is available so inquiry view can prefill guest details
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(AuthRepository(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(
        AuthController(authRepository: Get.find<AuthRepository>()),
        permanent: true,
      );
    }

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
