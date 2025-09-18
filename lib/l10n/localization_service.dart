import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

import '../app/data/services/locale_service.dart';

class LocalizationService extends Translations {
  // Supported locales
  static const fallbackLocale = Locale('en', 'US');
  static final List<String> langs = ['English', 'हिन्दी'];
  static final List<Locale> locales = [
    const Locale('en', 'US'),
    const Locale('hi', 'IN'),
  ];

  // Loaded keys map (e.g. {'en_US': {...}, 'hi_IN': {...}})
  static final Map<String, Map<String, String>> _keys = {};

  // Initial locale is resolved and assigned during init()
  static Locale initialLocale = fallbackLocale;

  @override
  Map<String, Map<String, String>> get keys => _keys;

  // Initialize by loading JSON assets and reading saved locale
  static Future<void> init(LocaleService localeService) async {
    // Resolve saved locale
    initialLocale = localeService.loadLocale() ?? fallbackLocale;

    // Load JSON files and flatten nested maps to dot.notation
    final enJson = await rootBundle.loadString('l10n/en.json');
    final hiJson = await rootBundle.loadString('l10n/hi.json');

    _keys['en_US'] = _flatten(json.decode(enJson) as Map<String, dynamic>);
    _keys['hi_IN'] = _flatten(json.decode(hiJson) as Map<String, dynamic>);
  }

  // Change locale by language display name (e.g. 'English')
  static Future<void> changeLocale(String lang, LocaleService localeService) async {
    final locale = _getLocaleFromLanguage(lang);
    await _updateLocale(locale, localeService);
  }

  // Change locale directly
  static Future<void> updateLocale(Locale locale, LocaleService localeService) async {
    await _updateLocale(locale, localeService);
  }

  static Future<void> _updateLocale(Locale locale, LocaleService localeService) async {
    await localeService.saveLocale(locale);
    Get.updateLocale(locale);
  }

  static Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale ?? initialLocale;
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
      result[newKey] = value?.toString() ?? '';
    }
  });
  return result;
}
