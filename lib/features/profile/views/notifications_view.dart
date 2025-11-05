import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/profile/controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification settings'),
        actions: [
          Obx(
            () => IconButton(
              icon:
                  controller.isSaving.value
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              onPressed: controller.isSaving.value ? null : controller.save,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              SwitchListTile.adaptive(
                title: const Text('Push notifications'),
                subtitle: const Text('Enquiry updates, reminders, and offers'),
                value: controller.pushEnabled.value,
                onChanged: (value) => controller.pushEnabled.value = value,
              ),
              SwitchListTile.adaptive(
                title: const Text('Email notifications'),
                subtitle: const Text('Enquiries, receipts, and personalised tips'),
                value: controller.emailEnabled.value,
                onChanged: (value) => controller.emailEnabled.value = value,
              ),
              const SizedBox(height: 24),
              Text(
                'Quiet hours',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _QuietHourTile(
                label: 'Start',
                time: controller.quietHoursStart.value,
                onTap: () => controller.pickQuietHoursStart(context),
              ),
              _QuietHourTile(
                label: 'End',
                time: controller.quietHoursEnd.value,
                onTap: () => controller.pickQuietHoursEnd(context),
              ),
              const SizedBox(height: 24),
              Text(
                'Notification frequency',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children:
                    controller.supportedFrequencies
                        .map(
                          (option) => ChoiceChip(
                            label: Text(option.capitalizeFirst ?? option),
                            selected: controller.frequency.value == option,
                            onSelected:
                                (_) => controller.frequency.value = option,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Notification categories',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...controller.categories.keys.map(
                (key) => CheckboxListTile(
                  value: controller.categories[key] ?? false,
                  onChanged:
                      (value) => controller.toggleCategory(key, value ?? false),
                  title: Text(key.capitalizeFirst ?? key),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: controller.isSaving.value ? null : controller.save,
                icon:
                    controller.isSaving.value
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.notifications_active_outlined),
                label: Text(
                  controller.isSaving.value
                      ? 'Saving settings...'
                      : 'Save notification settings',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietHourTile extends StatelessWidget {
  const _QuietHourTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      title: Text(label),
      subtitle: Text(_format(time)),
      trailing: const Icon(Icons.schedule_outlined),
    );
  }

  String _format(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
