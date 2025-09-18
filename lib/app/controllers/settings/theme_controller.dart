import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/theme_service.dart';

class ThemeController extends GetxController {
  ThemeController({required ThemeService themeService})
    : _themeService = themeService;

  final ThemeService _themeService;

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _themeService.loadThemeMode();
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  bool get isSystemMode => themeMode.value == ThemeMode.system;

  Future<void> toggleDarkMode(bool isDark) async {
    await updateThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    await _themeService.saveThemeMode(mode);
    Get.changeThemeMode(mode);
  }
}
