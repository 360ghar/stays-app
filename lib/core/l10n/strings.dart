import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/core/providers/app_settings_providers.dart';
import 'package:stays_app/l10n/localization_service.dart';

/// String helpers bound to the single app-wide locale.
///
/// The writable locale state lives in [localeProvider] ([LocaleNotifier] in
/// `core/providers/app_settings_providers.dart`), which also drives
/// `MaterialApp.router` locale and persists via `LocaleService`. This file
/// holds no locale state of its own; [tr]/[trOf] simply read that notifier.

/// Reads a localized string for the v2 locale. Falls back to English,
/// then to the key itself when missing.
String tr(WidgetRef ref, String key) {
  final locale = ref.watch(localeProvider);
  final tag = '${locale.languageCode}_${locale.countryCode}';
  final keys = LocalizationService.keys;
  return keys[tag]?[key] ?? keys['en_US']?[key] ?? key;
}

/// Non-widget variant for providers and callbacks.
String trOf(Ref ref, String key) {
  final locale = ref.watch(localeProvider);
  final tag = '${locale.languageCode}_${locale.countryCode}';
  final keys = LocalizationService.keys;
  return keys[tag]?[key] ?? keys['en_US']?[key] ?? key;
}
