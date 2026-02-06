import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/features/settings/controllers/theme_controller.dart';
import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/profile_repository.dart';
import 'package:stays_app/app/data/services/locale_service.dart';
import 'package:stays_app/app/utils/extensions/dynamic_extensions.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/features/profile/controllers/profile_controller.dart';
import 'package:stays_app/l10n/localization_service.dart';

class PreferencesController extends BaseController {
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

  final RxString feedbackMessage = ''.obs;

  /// Alias for isLoading from BaseController for backwards compatibility
  RxBool get isSaving => isLoading;

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
    trackWorker(ever<UserModel?>(_profileController.user, _hydrateFromUser));
    trackWorker(ever<ThemeMode>(
      _themeController.themeMode,
      (mode) => themeMode.value = _themeModeToString(mode),
    ));
  }

  @override
  void onClose() {
    // Workers are automatically disposed by BaseController via trackWorker
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
    autoLocation.value = parseBool(prefs['autoLocation'], fallback: false);
    marketingEmails.value = parseBool(prefs['marketingEmails'], fallback: false);
    travelAlerts.value = parseBool(prefs['travelAlerts'], fallback: true);
    currency.value = (prefs['currency'] ?? currency.value).toString();
  }

  Future<void> save() async {
    if (isLoading.value) return;
    final payload = {
      'theme': themeMode.value,
      'language': language.value,
      'autoLocation': autoLocation.value,
      'marketingEmails': marketingEmails.value,
      'travelAlerts': travelAlerts.value,
      'currency': currency.value,
    };
    final result = await executeWithErrorHandling(() async {
      final updatedUser = await _profileRepository.updatePreferences(payload);
      _profileController.updateUser(updatedUser);
      _profileController.updatePreferencesLocal(payload);
      return updatedUser;
    });
    if (result != null) {
      feedbackMessage.value = 'Preferences updated';
      AppSnackbar.success(
        title: 'Preferences',
        message: feedbackMessage.value,
      );
    } else {
      AppSnackbar.error(
        title: 'Update failed',
        message: 'We could not update your preferences. Please try again.',
      );
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
