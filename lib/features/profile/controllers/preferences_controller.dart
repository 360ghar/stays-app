import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/settings/theme_controller.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/services/locale_service.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';
import 'package:stays_app/l10n/localization_service.dart';

class PreferencesController extends GetxController {
  PreferencesController({
    required ProfileRepository profileRepository,
    required ProfileController profileController,
    required ThemeController themeController,
    required LocaleService localeService,
  }) : _profileRepository = profileRepository,
       _profileController = profileController,
       _themeController = themeController,
       _localeService = localeService;

  final ProfileRepository _profileRepository;
  final ProfileController _profileController;
  final ThemeController _themeController;
  final LocaleService _localeService;

  final RxString themeMode = 'system'.obs;
  final RxString language = 'en'.obs;
  final RxBool autoLocation = false.obs;
  final RxBool marketingEmails = false.obs;
  final RxBool travelAlerts = true.obs;
  final RxString currency = 'INR'.obs;

  final RxBool isSaving = false.obs;
  final RxString feedbackMessage = ''.obs;

  Worker? _userWorker;
  Worker? _themeWorker;

  List<String> get supportedThemes => const ['light', 'dark', 'system'];

  List<Map<String, String>> get supportedLanguages => const [
    {'code': 'en', 'label': 'English'},
    {'code': 'hi', 'label': 'Hindi'},
  ];

  List<String> get supportedCurrencies => const ['INR', 'USD', 'EUR'];

  @override
  void onInit() {
    super.onInit();
    _syncFromSystem();
    _hydrateFromUser(_profileController.user.value);
    _userWorker = ever<UserModel?>(_profileController.user, _hydrateFromUser);
    _themeWorker = ever<ThemeMode>(
      _themeController.themeMode,
      (mode) => themeMode.value = _themeModeToString(mode),
    );
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    _themeWorker?.dispose();
    super.onClose();
  }

  void _syncFromSystem() {
    themeMode.value = _themeModeToString(_themeController.themeMode.value);
    final currentLocale = Get.locale ?? LocalizationService.initialLocale;
    language.value = currentLocale.languageCode;
  }

  void _hydrateFromUser(UserModel? user) {
    if (user == null) return;
    final prefs = user.preferences ?? {};
    final prefTheme = (prefs['theme'] as String?)?.toLowerCase();
    if (prefTheme != null && supportedThemes.contains(prefTheme)) {
      themeMode.value = prefTheme;
    }
    final prefLanguage = (prefs['language'] as String?)?.toLowerCase();
    if (prefLanguage != null && prefLanguage.isNotEmpty) {
      language.value = prefLanguage;
    }
    autoLocation.value = _asBool(prefs['autoLocation'], fallback: false);
    marketingEmails.value = _asBool(prefs['marketingEmails'], fallback: false);
    travelAlerts.value = _asBool(prefs['travelAlerts'], fallback: true);
    currency.value = (prefs['currency'] ?? currency.value).toString();
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return fallback;
  }

  Future<void> save() async {
    if (isSaving.value) return;
    try {
      isSaving.value = true;
      final payload = {
        'theme': themeMode.value,
        'language': language.value,
        'autoLocation': autoLocation.value,
        'marketingEmails': marketingEmails.value,
        'travelAlerts': travelAlerts.value,
        'currency': currency.value,
      };
      final updatedUser = await _profileRepository.updatePreferences(payload);
      _profileController.updateUser(updatedUser);
      _profileController.updatePreferencesLocal(payload);
      feedbackMessage.value = 'Preferences updated';
      Get.snackbar(
        'Preferences',
        feedbackMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to update preferences', e, stack);
      Get.snackbar(
        'Update failed',
        'We could not update your preferences. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  void selectTheme(String mode) {
    if (!supportedThemes.contains(mode)) return;
    themeMode.value = mode;
    final theme = _themeModeFromString(mode);
    if (_themeController.themeMode.value != theme) {
      unawaited(_themeController.updateThemeMode(theme));
    }
  }

  void selectLanguage(String code) {
    if (supportedLanguages.every((entry) => entry['code'] != code)) return;
    language.value = code;
    final target = _localeFromCode(code);
    final current = Get.locale ?? LocalizationService.initialLocale;
    final sameLanguage =
        current.languageCode == target.languageCode &&
        (current.countryCode ?? '') == (target.countryCode ?? '');
    if (!sameLanguage) {
      unawaited(LocalizationService.updateLocale(target, _localeService));
    }
  }

  void selectCurrency(String value) {
    if (!supportedCurrencies.contains(value)) return;
    currency.value = value;
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Locale _localeFromCode(String code) {
    switch (code) {
      case 'hi':
        return const Locale('hi', 'IN');
      case 'en':
      default:
        return const Locale('en', 'US');
    }
  }
}
