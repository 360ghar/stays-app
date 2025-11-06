import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/locale_service.dart';
import '../../../l10n/localization_service.dart';
import '../../utils/logger/app_logger.dart';

import 'theme_controller.dart';

class ThemeOption {
  const ThemeOption({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
  });

  final ThemeMode mode;
  // These hold translation keys (resolved with .tr in the view)
  final String title;
  final String description;
  final IconData icon;
}

class SettingsController extends GetxController {
  SettingsController({required ThemeController themeController})
    : _themeController = themeController;

  final ThemeController _themeController;

  static const List<ThemeOption> _themeOptions = [
    ThemeOption(
      mode: ThemeMode.system,
      title: 'settings.theme.system_title',
      description: 'settings.theme.system_desc',
      icon: Icons.auto_awesome,
    ),
    ThemeOption(
      mode: ThemeMode.light,
      title: 'settings.theme.light_title',
      description: 'settings.theme.light_desc',
      icon: Icons.wb_sunny_rounded,
    ),
    ThemeOption(
      mode: ThemeMode.dark,
      title: 'settings.theme.dark_title',
      description: 'settings.theme.dark_desc',
      icon: Icons.nightlight_round,
    ),
  ];

  Rx<ThemeMode> get themeMode => _themeController.themeMode;

  ThemeMode get selectedThemeMode => _themeController.themeMode.value;

  List<ThemeOption> get themeOptions => _themeOptions;

  Future<void> selectTheme(ThemeMode mode) async {
    await _themeController.updateThemeMode(mode);
  }

  Future<void> toggleDarkMode(bool isDark) async {
    await _themeController.toggleDarkMode(isDark);
  }

  // Language selection (driven by LocalizationService)
  final Rx<Locale> selectedLocale =
      (Get.locale ?? LocalizationService.initialLocale).obs;

  List<LanguageOption> get languageOptions => const [
    LanguageOption(
      locale: Locale('en', 'US'),
      labelKey: 'settings.language.english',
      icon: Icons.language,
    ),
    LanguageOption(
      locale: Locale('hi', 'IN'),
      labelKey: 'settings.language.hindi',
      icon: Icons.translate,
    ),
  ];

  Future<void> selectLanguage(Locale locale) async {
    // Defer persistence/update to LocalizationService
    try {
      final localeService = Get.find<LocaleService>();
      await LocalizationService.updateLocale(locale, localeService);
      selectedLocale.value = locale;
      AppLogger.info(
        'Language changed to: ${locale.languageCode}_${locale.countryCode}',
      );
    } catch (e) {
      AppLogger.error('Failed to change language', e);
      // Fallback without service registered (shouldn't happen in production)
      Get.updateLocale(locale);
      selectedLocale.value = locale;
    }
  }
}

class LanguageOption {
  const LanguageOption({
    required this.locale,
    required this.labelKey,
    required this.icon,
  });

  final Locale locale;
  final String labelKey; // translation key resolved with .tr
  final IconData icon;
}
