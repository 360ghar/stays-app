import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';

  SharedPreferences? _prefs;

  Future<LocaleService> init() async {
    _prefs ??= await SharedPreferences.getInstance();
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
