import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stays_app/app/utils/storage/legacy_get_storage.dart';

class ThemeService {
  static const String _themeModeKey = 'theme_mode';
  static const String _legacyBox = 'theme_preferences';

  SharedPreferences? _prefs;

  Future<ThemeService> init() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    // One-time move of the choice an older build kept with GetStorage.
    if (!prefs.containsKey(_themeModeKey)) {
      final old = (await LegacyGetStorage.read(_legacyBox))[_themeModeKey];
      if (old is String) await prefs.setString(_themeModeKey, old);
    }
    await LegacyGetStorage.delete(_legacyBox);
    return this;
  }

  ThemeMode loadThemeMode() {
    switch (_prefs?.getString(_themeModeKey)) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}
