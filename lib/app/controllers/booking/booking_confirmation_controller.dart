import 'package:get/get.dart';

import '../../data/models/property_model.dart';
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
          'Enquiry unavailable',
          'We could not load the property details. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }
  }

  Future<void> submitEnquiry() async {
    final selectedProperty = property.value;
    if (selectedProperty == null) {
      Get.snackbar(
        'Enquiry unavailable',
        'No property was provided for this enquiry.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    TripsController tripsController;
    try {
      tripsController = Get.find<TripsController>();
    } catch (_) {
      Get.snackbar(
        'Enquiry unavailable',
        'We could not update your enquiries right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    tripsController.addBooking(selectedProperty);

    await Get.offAllNamed(Routes.home, arguments: 0);
  }
}
