import 'package:get/get.dart';

import '../../data/models/property_model.dart';
import '../activity_controller.dart';
import '../../routes/app_routes.dart';

class BookingConfirmationController extends GetxController {
  final Rxn<Property> property = Rxn<Property>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Property) {
      property.value = args;
    } else if (args is Map && args['property'] is Property) {
      property.value = args['property'] as Property;
    }

    if (property.value == null) {
      Future.microtask(() {
        Get.snackbar(
          'Booking unavailable',
          'We could not load the property details. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }
  }

  Future<void> confirmBookingAndPay() async {
    final selectedProperty = property.value;
    if (selectedProperty == null) {
      Get.snackbar(
        'Booking unavailable',
        'No property was provided for confirmation.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    ActivityController activityController;
    try {
      activityController = Get.find<ActivityController>();
    } catch (_) {
      Get.snackbar(
        'Activity unavailable',
        'We could not update your activity right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    activityController.addBooking(selectedProperty);

    await Get.offAllNamed(Routes.home, arguments: 0);
  }
}
