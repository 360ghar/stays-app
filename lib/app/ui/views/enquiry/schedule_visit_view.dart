import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../controllers/enquiry/schedule_visit_controller.dart';

class ScheduleVisitView extends GetView<ScheduleVisitController> {
  const ScheduleVisitView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule a Visit'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.property.name,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.property.address ??
                    controller.property.fullAddress ??
                    controller.property.city,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select a date',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _ScheduleDatePicker(controller: controller),
              const SizedBox(height: 24),
              Text(
                'Select a time',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _ScheduleTimePicker(controller: controller),
              const SizedBox(height: 24),
              Obx(() {
                final selectedDate = controller.selectedDate.value;
                final selectedTime = controller.selectedTime.value;
                if (selectedDate == null || selectedTime == null) {
                  return const SizedBox.shrink();
                }
                final displayDate =
                    DateFormat('EEE, MMM d').format(selectedDate);
                final displayTime = selectedTime.format(context);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requested slot',
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$displayDate · $displayTime',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: Obx(
          () => FilledButton(
            onPressed: controller.isSubmitting.value
                ? null
                : controller.submitSchedule,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: controller.isSubmitting.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm Schedule'),
          ),
        ),
      ),
    );
  }
}

class _ScheduleDatePicker extends StatelessWidget {
  const _ScheduleDatePicker({required this.controller});

  final ScheduleVisitController controller;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: CalendarDatePicker(
        initialDate: controller.selectedDate.value ?? now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 120)),
        onDateChanged: controller.selectDate,
      ),
    );
  }
}

class _ScheduleTimePicker extends StatelessWidget {
  const _ScheduleTimePicker({required this.controller});

  final ScheduleVisitController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: () async {
          final initialTime =
              controller.selectedTime.value ?? TimeOfDay.now();
          final picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
          );
          if (picked != null) {
            controller.selectTime(picked);
          }
        },
        icon: const Icon(Icons.access_time),
        label: Text(
          controller.selectedTime.value?.format(context) ?? 'Choose time',
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
