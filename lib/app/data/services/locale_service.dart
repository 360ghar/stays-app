import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleService extends GetxService {
  static const String _boxName = 'locale_preferences';
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';

  late final GetStorage _box;

  Future<LocaleService> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    return this;
  }

  Locale? loadLocale() {
    final lang = _box.read<String>(_languageCodeKey);
    final country = _box.read<String>(_countryCodeKey);
    if (lang == null || lang.isEmpty) return null;
    if (country != null && country.isNotEmpty) {
      return Locale(lang, country);
    }
    return Locale(lang);
  }

  Future<void> saveLocale(Locale locale) async {
    await _box.write(_languageCodeKey, locale.languageCode);
    await _box.write(_countryCodeKey, locale.countryCode ?? '');
  }
}

