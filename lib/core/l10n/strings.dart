import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/l10n/localization_service.dart';

/// V2 locale state. Seeded from the saved locale loaded at boot.
final localeProvider = StateProvider<Locale>(
  (_) => LocalizationService.initialLocale,
);

/// Reads a localized string for the v2 locale. Falls back to English,
/// then to the key itself when missing.
String tr(WidgetRef ref, String key) {
  final locale = ref.watch(localeProvider);
  final tag = '${locale.languageCode}_${locale.countryCode}';
  final keys = LocalizationService().keys;
  return keys[tag]?[key] ?? keys['en_US']?[key] ?? key;
}

/// Non-widget variant for providers and callbacks.
String trOf(Ref ref, String key) {
  final locale = ref.watch(localeProvider);
  final tag = '${locale.languageCode}_${locale.countryCode}';
  final keys = LocalizationService().keys;
  return keys[tag]?[key] ?? keys['en_US']?[key] ?? key;
}
