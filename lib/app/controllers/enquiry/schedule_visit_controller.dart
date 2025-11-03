import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/property_model.dart';
import '../../data/repositories/visit_repository.dart';
import '../../utils/logger/app_logger.dart';

class ScheduleVisitController extends GetxController {
  ScheduleVisitController({required VisitRepository repository})
    : _repository = repository;

  final VisitRepository _repository;

  late final Property property;

  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> selectedTime = Rx<TimeOfDay?>(null);
  final RxBool isSubmitting = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Property) {
      property = args;
      return;
    }
    AppLogger.error(
      'ScheduleVisitController initialized without property argument',
      args,
    );
    throw ArgumentError(
      'ScheduleVisitController expects a Property instance in Get.arguments',
    );
  }

  void selectDate(DateTime date) => selectedDate.value = date;

  void selectTime(TimeOfDay time) => selectedTime.value = time;

  Future<void> submitSchedule() async {
    final date = selectedDate.value;
    final time = selectedTime.value;
    if (date == null || time == null) {
      Get.snackbar(
        'Missing details',
        'Please select both a date and a time.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final scheduledDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    isSubmitting.value = true;
    try {
      await _repository.createVisit({
        'property_id': property.id,
        'scheduled_date': scheduledDate.toIso8601String(),
      });

      Get.back(result: true);
      Get.snackbar(
        'Success!',
        'We will send you confirmation shortly.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (error) {
      AppLogger.error('Failed to schedule visit', error);
      Get.snackbar(
        'Could not schedule visit',
        'Please try again in a moment.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
