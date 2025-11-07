import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'app/utils/security/security_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.staging');
  AppConfig.setConfig(AppConfig.staging());
  if (Get.isRegistered<SecurityService>()) {
    SecurityService.I.validateApiKeys();
  }
  final pinsRaw = dotenv.env['API_CERT_SHA256'];
  if (pinsRaw != null && pinsRaw.trim().isNotEmpty) {
    final host = Uri.parse(AppConfig.I.apiBaseUrl).host;
    final pins = pinsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (pins.isNotEmpty) {
      HttpOverrides.global = PinningHttpOverrides(allowedPins: pins, host: host);
    }
  }

  final themeService = await Get.putAsync<ThemeService>(
    () async => ThemeService().init(),
    permanent: true,
  );

  Get.put<ThemeController>(
    ThemeController(themeService: themeService),
    permanent: true,
  );
  // Locale service + load translations
  final localeService = await Get.putAsync<LocaleService>(
    () async => LocaleService().init(),
    permanent: true,
  );
  await LocalizationService.init(localeService);
  Get.updateLocale(LocalizationService.initialLocale);
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
    return Obx(() {
      final currentLocale = Get.locale ?? LocalizationService.initialLocale;
      return GetMaterialApp(
        title: '360ghar stays (Staging)',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        translations: LocalizationService(),
        locale: currentLocale,
        fallbackLocale: LocalizationService.fallbackLocale,
        supportedLocales: LocalizationService.locales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialBinding: InitialBinding(),
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
