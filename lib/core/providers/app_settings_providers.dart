import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/services/locale_service.dart';
import 'package:stays_app/app/data/services/theme_service.dart';
import 'package:stays_app/l10n/localization_service.dart';

/// Service handles. Overridden in every entry point (`main*.dart`) with the
/// initialized instances so providers never touch GetX.
final themeServiceProvider = Provider<ThemeService>(
  (_) => throw UnimplementedError('themeServiceProvider not overridden'),
);

final localeServiceProvider = Provider<LocaleService>(
  (_) => throw UnimplementedError('localeServiceProvider not overridden'),
);

/// App-wide theme mode. Replaces the legacy GetX `ThemeController`.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(themeServiceProvider).loadThemeMode();

  bool get isDarkMode => state == ThemeMode.dark;

  bool get isSystemMode => state == ThemeMode.system;

  Future<void> toggleDarkMode({required bool isDark}) async {
    await updateThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ref.read(themeServiceProvider).saveThemeMode(mode);
  }
}

/// App-wide locale. Replaces `Get.locale` / `Get.updateLocale`.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => LocalizationService.initialLocale;

  Future<void> updateLocale(Locale locale) async {
    if (state == locale) return;
    await ref.read(localeServiceProvider).saveLocale(locale);
    state = locale;
  }

  Future<void> changeLocaleByName(String lang) async {
    final index = LocalizationService.langs.indexOf(lang);
    final locale = index >= 0
        ? LocalizationService.locales[index]
        : LocalizationService.fallbackLocale;
    await updateLocale(locale);
  }
}
