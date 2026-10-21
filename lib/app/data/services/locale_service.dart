import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stays_app/app/utils/storage/legacy_get_storage.dart';

class LocaleService {
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';
  static const String _legacyBox = 'locale_preferences';

  SharedPreferences? _prefs;

  Future<LocaleService> init() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    // One-time move of the language an older build kept with GetStorage.
    if (!prefs.containsKey(_languageCodeKey)) {
      final old = await LegacyGetStorage.read(_legacyBox);
      final lang = old[_languageCodeKey];
      final country = old[_countryCodeKey];
      if (lang is String && lang.isNotEmpty) {
        await prefs.setString(_languageCodeKey, lang);
        await prefs.setString(
          _countryCodeKey,
          country is String ? country : '',
        );
      }
    }
    await LegacyGetStorage.delete(_legacyBox);
    return this;
  }

  Locale? loadLocale() {
    final lang = _prefs?.getString(_languageCodeKey);
    final country = _prefs?.getString(_countryCodeKey);
    if (lang == null || lang.isEmpty) return null;
    if (country != null && country.isNotEmpty) {
      return Locale(lang, country);
    }
    return Locale(lang);
  }

  Future<void> saveLocale(Locale locale) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
    await prefs.setString(_countryCodeKey, locale.countryCode ?? '');
  }
}
