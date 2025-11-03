import 'package:get/get.dart';

import '../controllers/activity_controller.dart';
import '../controllers/filter_controller.dart';
import '../data/providers/bookings_provider.dart';
import '../data/providers/visit_provider.dart';
import '../data/repositories/booking_repository.dart';
import '../data/repositories/visit_repository.dart';

class ActivityBinding extends Bindings {
  @override
  void dependencies() {
    final bookingsProvider =
        Get.isRegistered<BookingsProvider>()
            ? Get.find<BookingsProvider>()
            : Get.put(BookingsProvider(), permanent: true);

    if (!Get.isRegistered<BookingRepository>()) {
      Get.put<BookingRepository>(
        BookingRepository(provider: bookingsProvider),
        permanent: true,
      );
    }

    if (!Get.isRegistered<VisitProvider>()) {
      Get.put<VisitProvider>(VisitProvider(), permanent: true);
    }

    if (!Get.isRegistered<VisitRepository>()) {
      Get.put<VisitRepository>(
        VisitRepository(provider: Get.find<VisitProvider>()),
        permanent: true,
      );
    }

    if (!Get.isRegistered<FilterController>()) {
      Get.put<FilterController>(FilterController(), permanent: true);
    }

    if (!Get.isRegistered<ActivityController>()) {
      Get.put<ActivityController>(ActivityController(), permanent: true);
    }
  }
}
