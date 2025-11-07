import 'package:get/get.dart';

import '../controllers/inquiry/inquiry_controller.dart';
import '../controllers/inquiry/inquiry_confirmation_controller.dart';
import '../data/repositories/booking_repository.dart';
import '../controllers/trips_controller.dart';
import 'trips_binding.dart';
import '../data/providers/bookings_provider.dart';
import '../controllers/auth/auth_controller.dart';
import '../data/repositories/auth_repository.dart';
import '../data/providers/auth/i_auth_provider.dart';
import '../data/providers/supabase_auth_provider.dart';

class InquiryBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure auth is available so inquiry view can prefill guest details
    if (!Get.isRegistered<IAuthProvider>()) {
      Get.put<IAuthProvider>(SupabaseAuthProvider(), permanent: true);
    }
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(
        AuthRepository(provider: Get.find<IAuthProvider>()),
        permanent: true,
      );
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
