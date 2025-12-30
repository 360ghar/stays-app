import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/data/services/theme_service.dart';
import 'package:stays_app/features/settings/controllers/theme_controller.dart';

class _FakeThemeService extends ThemeService {
  ThemeMode storedMode = ThemeMode.light;

  @override
  Future<ThemeService> init() async => this;

  @override
  ThemeMode loadThemeMode() => storedMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    storedMode = mode;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  test('ThemeController loads stored theme on init', () {
    final service = _FakeThemeService()..storedMode = ThemeMode.dark;
    final controller = ThemeController(themeService: service)..onInit();

    expect(controller.themeMode.value, ThemeMode.dark);
  });

  test('ThemeController update persists to ThemeService', () async {
    final service = _FakeThemeService();
    final controller = ThemeController(themeService: service)..onInit();

    await controller.updateThemeMode(ThemeMode.dark);

    expect(controller.themeMode.value, ThemeMode.dark);
    expect(service.storedMode, ThemeMode.dark);
  });

  test(
    'ThemeController toggleDarkMode toggles between light and dark',
    () async {
      final service = _FakeThemeService();
      final controller = ThemeController(themeService: service)..onInit();

      await controller.toggleDarkMode(true);
      expect(controller.themeMode.value, ThemeMode.dark);

      await controller.toggleDarkMode(false);
      expect(controller.themeMode.value, ThemeMode.light);
    },
  );
}
