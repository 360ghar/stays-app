import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService extends GetxService {
  static const String _boxName = 'theme_preferences';
  static const String _themeModeKey = 'theme_mode';

  late final GetStorage _box;

  Future<ThemeService> init() async {
    await GetStorage.init(_boxName);
    _box = GetStorage(_boxName);
    return this;
  }

  ThemeMode loadThemeMode() {
    final stored = _box.read<String>(_themeModeKey);
    switch (stored) {
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
    await _box.write(_themeModeKey, mode.name);
  }
}
