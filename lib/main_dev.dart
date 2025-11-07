import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'l10n/localization_service.dart';
import 'app/data/services/locale_service.dart';
import 'app/ui/theme/app_theme.dart';
import 'app/data/services/theme_service.dart';
import 'app/controllers/settings/theme_controller.dart';
import 'app/utils/security/cert_pinning.dart';
import 'app/utils/logger/app_logger.dart';
import 'app/utils/security/security_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env.dev');
  AppConfig.setConfig(AppConfig.dev());
  // Validate high-level API keys
  if (Get.isRegistered<SecurityService>()) {
    SecurityService.I.validateApiKeys();
  }
  final pinsRaw = dotenv.env['API_CERT_SHA256'];
  if (pinsRaw != null && pinsRaw.trim().isNotEmpty) {
    final host = Uri.parse(AppConfig.I.apiBaseUrl).host;
    final pins = pinsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (pins.isNotEmpty) {
      HttpOverrides.global = PinningHttpOverrides(allowedPins: pins, host: host);
      AppLogger.info('Certificate pinning enabled for $host');
    }
  }

  // 🔹 Theme Service
  final themeService = await Get.putAsync<ThemeService>(
    () async => ThemeService().init(),
    permanent: true,
  );

  // 🔹 Theme Controller
  Get.put<ThemeController>(
    ThemeController(themeService: themeService),
    permanent: true,
  );

  // 🔹 Locale Service + Translations
  final localeService = await Get.putAsync<LocaleService>(
    () async => LocaleService().init(),
    permanent: true,
  );

  await LocalizationService.init(localeService);
  Get.updateLocale(LocalizationService.initialLocale);
  AppLogger.info(
    'Localization initialized with locale: ${LocalizationService.initialLocale}',
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      title: '360ghar stays (Dev)',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode.value,
      translations: LocalizationService(),
      locale: LocalizationService.initialLocale,
      fallbackLocale: LocalizationService.fallbackLocale,
      supportedLocales: LocalizationService.locales,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
