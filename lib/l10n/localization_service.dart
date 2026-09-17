import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app/data/services/locale_service.dart';
import '../app/utils/logger/app_logger.dart';

/// Static string tables loaded from JSON assets at boot.
///
/// The single writable locale state is [LocaleNotifier] (`localeProvider` in
/// `core/providers/app_settings_providers.dart`), seeded from [initialLocale]
/// at startup; it drives `MaterialApp.router` locale, `tr()`/`trOf()`, and
/// persists via `LocaleService`. [updateLocale]/[changeLocale] below are
/// persistence-only helpers that update [initialLocale] for pre-boot use —
/// they do NOT notify the provider. Runtime language changes must go through
/// `LocaleNotifier.updateLocale`/`changeLocaleByName`.
class LocalizationService {
  // Supported locales
  static const fallbackLocale = Locale('en', 'US');
  static final List<String> langs = ['English', 'हिन्दी'];
  static final List<Locale> locales = [
    const Locale('en', 'US'),
    const Locale('hi', 'IN'),
  ];

  // Loaded keys map with fallback support
  static final Map<String, Map<String, String>> _keys = {};

  // Initial locale is resolved and assigned during init()
  static Locale initialLocale = fallbackLocale;

  static Map<String, Map<String, String>> get keys => _keys;

  // Initialize by loading JSON assets and reading saved locale
  static Future<void> init(LocaleService localeService) async {
    // Resolve saved locale
    initialLocale = localeService.loadLocale() ?? fallbackLocale;

    try {
      // Load JSON files asynchronously and flatten nested maps to dot.notation
      final futures = await Future.wait([
        rootBundle.loadString('l10n/en.json'),
        rootBundle.loadString('l10n/hi.json'),
      ]);

      final enJson = futures[0];
      final hiJson = futures[1];

      // Load English translations
      final englishKeys = _flatten(json.decode(enJson) as Map<String, dynamic>);
      _keys['en_US'] = englishKeys;

      // Load Hindi translations with English fallback
      final hindiKeys = _flatten(json.decode(hiJson) as Map<String, dynamic>);
      _keys['hi_IN'] = _createFallbackMap(hindiKeys, englishKeys);

      // Log missing keys for debugging
      _logMissingKeys(hindiKeys, englishKeys);
    } catch (e) {
      // Fallback to empty maps if asset loading fails
      _keys['en_US'] = {};
      _keys['hi_IN'] = {};
      // Log the error but don't crash the app
      AppLogger.error('Error loading localization assets', e);
    }
  }

  // Create a map with Hindi keys, falling back to English for missing keys
  static Map<String, String> _createFallbackMap(
    Map<String, String> hindiKeys,
    Map<String, String> englishKeys,
  ) {
    final result = Map<String, String>.from(englishKeys); // Start with English
    result.addAll(hindiKeys); // Override with Hindi translations
    return result;
  }

  // Log missing keys for debugging
  static void _logMissingKeys(
    Map<String, String> hindiKeys,
    Map<String, String> englishKeys,
  ) {
    final missingKeys = englishKeys.keys
        .where((key) => !hindiKeys.containsKey(key))
        .toList();
    if (missingKeys.isNotEmpty) {
      AppLogger.warning(
        'Missing Hindi translations for keys: ${missingKeys.join(', ')}',
      );
    }
  }

  // Change locale by language display name (e.g. 'English').
  // Persistence-only: updates [initialLocale] for pre-boot coherence.
  // Runtime changes must go through LocaleNotifier instead.
  static Future<void> changeLocale(
    String lang,
    LocaleService localeService,
  ) async {
    final locale = _getLocaleFromLanguage(lang);
    await _updateLocale(locale, localeService);
  }

  // Change locale directly.
  // Persistence-only: updates [initialLocale] for pre-boot coherence.
  // Runtime changes must go through LocaleNotifier instead.
  static Future<void> updateLocale(
    Locale locale,
    LocaleService localeService,
  ) async {
    await _updateLocale(locale, localeService);
  }

  static Future<void> _updateLocale(
    Locale locale,
    LocaleService localeService,
  ) async {
    await localeService.saveLocale(locale);
    initialLocale = locale;
  }

  static Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return initialLocale;
  }
}

// Flatten nested JSON objects into a Map<String, String> with dot.notation keys
Map<String, String> _flatten(Map<String, dynamic> json, [String prefix = '']) {
  final Map<String, String> result = {};
  json.forEach((key, value) {
    final newKey = prefix.isEmpty ? key : '$prefix.$key';
    if (value is Map<String, dynamic>) {
      result.addAll(_flatten(value, newKey));
    } else {
      final stringValue = value?.toString() ?? '';
      // Skip empty values to prevent issues
      if (stringValue.isNotEmpty) {
        result[newKey] = stringValue;
      }
    }
  });
  return result;
}
