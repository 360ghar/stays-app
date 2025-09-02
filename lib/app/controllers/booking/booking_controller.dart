import 'package:get/get.dart';

import '../../data/repositories/booking_repository.dart';

class BookingController extends GetxController {
  final BookingRepository _repository;
  BookingController({required BookingRepository repository}) : _repository = repository;

  final RxBool isSubmitting = false.obs;
  final RxString statusMessage = ''.obs;

  Future<void> createBooking(Map<String, dynamic> payload) async {
    try {
      isSubmitting.value = true;
      await _repository.createBooking(payload);
      statusMessage.value = 'Booking created';
    } catch (e) {
      statusMessage.value = 'Failed to create booking';
    } finally {
      isSubmitting.value = false;
    }
  }
}

