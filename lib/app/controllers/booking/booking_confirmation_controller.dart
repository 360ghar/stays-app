import 'package:get/get.dart';

import '../../data/models/property_model.dart';
import '../navigation_controller.dart';
import '../trips_controller.dart';
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

    TripsController tripsController;
    try {
      tripsController = Get.find<TripsController>();
    } catch (_) {
      Get.snackbar(
        'Trips unavailable',
        'We could not update your trips right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    tripsController.addBooking(selectedProperty);

    if (Get.isRegistered<NavigationController>()) {
      Get.find<NavigationController>().changeTab(2);
    }

    await Get.offAllNamed(Routes.home, arguments: {'tabIndex': 2});
  }
}
