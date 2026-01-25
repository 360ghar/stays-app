import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/utils/extensions/dynamic_extensions.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';

class NotificationsController extends BaseController {
  NotificationsController({
    required ProfileRepository profileRepository,
    required ProfileController profileController,
  }) : _profileRepository = profileRepository,
       _profileController = profileController;

  final ProfileRepository _profileRepository;
  final ProfileController _profileController;

  final RxBool pushEnabled = true.obs;
  final RxBool emailEnabled = true.obs;
  final Rx<TimeOfDay> quietHoursStart = Rx<TimeOfDay>(
    const TimeOfDay(hour: 22, minute: 0),
  );
  final Rx<TimeOfDay> quietHoursEnd = Rx<TimeOfDay>(
    const TimeOfDay(hour: 7, minute: 0),
  );
  final RxString frequency = 'daily'.obs;
  final RxMap<String, bool> categories = <String, bool>{
    'bookings': true,
    'promotions': false,
    'reminders': true,
    'community': false,
  }.obs;

  /// Alias for isLoading from BaseController for backwards compatibility
  RxBool get isSaving => isLoading;

  final List<String> supportedFrequencies = const [
    'realtime',
    'daily',
    'weekly',
  ];

  @override
  void onInit() {
    super.onInit();
    _hydrate(_profileController.user.value);
    trackWorker(ever<UserModel?>(_profileController.user, _hydrate));
  }

  @override
  void onClose() {
    // Workers are automatically disposed by BaseController via trackWorker
    super.onClose();
  }

  void _hydrate(UserModel? user) {
    if (user == null) return;
    final settings = user.notificationSettings ?? {};
    pushEnabled.value = parseBool(settings['push'], fallback: true);
    emailEnabled.value = parseBool(settings['email'], fallback: true);
    frequency.value = (settings['frequency'] ?? frequency.value).toString();

    final quietHours = settings['quietHours'];
    if (quietHours is Map) {
      quietHoursStart.value =
          _parseTimeOfDay(quietHours['start']) ?? quietHoursStart.value;
      quietHoursEnd.value =
          _parseTimeOfDay(quietHours['end']) ?? quietHoursEnd.value;
    }

    final dynamic cats = settings['categories'];
    if (cats is Map) {
      final parsed = <String, bool>{};
      for (final entry in cats.entries) {
        parsed[entry.key.toString()] =
            parseBool(entry.value, fallback: categories[entry.key.toString()] ?? false);
      }
      categories.assignAll(parsed);
    }
  }

  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value is TimeOfDay) return value;
    if (value is String && value.contains(':')) {
      final parts = value.split(':');
      final hour = int.tryParse(parts.first) ?? 0;
      final minute = int.tryParse(parts.last) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  String _timeToString(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> save() async {
    if (isLoading.value) return;
    final payload = {
      'push': pushEnabled.value,
      'email': emailEnabled.value,
      'frequency': frequency.value,
      'quietHours': {
        'start': _timeToString(quietHoursStart.value),
        'end': _timeToString(quietHoursEnd.value),
      },
      'categories': Map<String, bool>.from(categories),
    };
    final result = await executeWithErrorHandling(() async {
      final updated = await _profileRepository.updateNotificationSettings(
        payload,
      );
      _profileController.updateUser(updated);
      _profileController.updateNotificationSettingsLocal(payload);
      return updated;
    });
    if (result != null) {
      AppSnackbar.success(
        title: 'Notifications',
        message: 'Notification preferences updated',
      );
    } else {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'Unable to update notification settings. Please retry.',
      );
    }
  }

  Future<void> pickQuietHoursStart(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: quietHoursStart.value,
    );
    if (picked != null) {
      quietHoursStart.value = picked;
    }
  }

  Future<void> pickQuietHoursEnd(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: quietHoursEnd.value,
    );
    if (picked != null) {
      quietHoursEnd.value = picked;
    }
  }

  void toggleCategory(String key, bool enabled) {
    categories[key] = enabled;
  }
}
