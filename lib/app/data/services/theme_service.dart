import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeModeKey = 'theme_mode';

  SharedPreferences? _prefs;

  Future<ThemeService> init() async {
    _prefs ??= await SharedPreferences.getInstance();
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
