import 'package:get/get.dart';

import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';

class BookingController extends GetxController {
  final BookingRepository _repository;
  BookingController({required BookingRepository repository})
    : _repository = repository;

  final RxBool isSubmitting = false.obs;
  final RxString statusMessage = ''.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Booking> latestBooking = Rxn<Booking>();

  Future<void> createBooking(Map<String, dynamic> payload) async {
    try {
      errorMessage.value = '';
      isSubmitting.value = true;
      final booking = await _repository.createBooking(payload);
      latestBooking.value = booking;
      statusMessage.value = 'Booking created';
    } catch (e) {
      latestBooking.value = null;
      errorMessage.value = e.toString();
      statusMessage.value = 'Failed to create booking';
    } finally {
      isSubmitting.value = false;
    }
  }
}
