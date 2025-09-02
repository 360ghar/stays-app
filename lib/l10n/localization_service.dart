import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  static const locale = Locale('en', 'US');
  static const fallbackLocale = Locale('en', 'US');

  static final langs = ['English', 'Spanish', 'French'];
  static final locales = [
    const Locale('en', 'US'),
    const Locale('es', 'ES'),
    const Locale('fr', 'FR'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'es_ES': esES,
        'fr_FR': frFR,
      };

  static void changeLocale(String lang) {
    final locale = _getLocaleFromLanguage(lang);
    Get.updateLocale(locale);
  }

  static Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale ?? locale;
  }
}

const Map<String, String> enUS = {
  'app_name': '360ghar stays',
  'auth.login': 'Log In',
  'auth.signup': 'Sign Up',
  'home.explore_nearby': 'Explore Nearby',
};

const Map<String, String> esES = {
  'app_name': '360ghar stays',
  'auth.login': 'Iniciar sesión',
  'auth.signup': 'Regístrate',
  'home.explore_nearby': 'Explora Cerca',
};

const Map<String, String> frFR = {
  'app_name': '360ghar stays',
  'auth.login': 'Se connecter',
  'auth.signup': "S'inscrire",
  'home.explore_nearby': 'Explorer à proximité',
};

