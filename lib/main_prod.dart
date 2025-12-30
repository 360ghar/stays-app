import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/bindings/initial_binding.dart';
import 'app/data/services/locale_service.dart';
import 'app/data/services/theme_service.dart';
import 'app/routes/app_pages.dart';
import 'app/ui/theme/app_theme.dart';
import 'app/utils/performance/performance_monitor.dart';
import 'app/utils/security/cert_pinning.dart';
import 'app/utils/security/security_service.dart';
import 'app/utils/services/error_service.dart';
import 'config/app_config.dart';
import 'features/settings/controllers/theme_controller.dart';
import 'l10n/localization_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.prod');
  AppConfig.setConfig(AppConfig.prod());
  if (!Get.isRegistered<ErrorService>()) {
    Get.put<ErrorService>(ErrorService(), permanent: true);
  }
  if (!Get.isRegistered<PerformanceMonitor>()) {
    Get.put<PerformanceMonitor>(PerformanceMonitor(), permanent: true);
  }
  if (Get.isRegistered<SecurityService>()) {
    SecurityService.I.validateApiKeys();
  }
  final pinsRaw = dotenv.env['API_CERT_SHA256'];
  if (pinsRaw != null && pinsRaw.trim().isNotEmpty) {
    final host = Uri.parse(AppConfig.I.apiBaseUrl).host;
    final pins = pinsRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (pins.isNotEmpty) {
      HttpOverrides.global = PinningHttpOverrides(
        allowedPins: pins,
        host: host,
      );
    }
  }

  // Parallelize initialization of independent services for faster startup
  late ThemeService themeService;
  late LocaleService localeService;

  await Future.wait([
    // Theme service initialization
    ThemeService().init().then((service) => themeService = service),
    // Locale service initialization
    LocaleService().init().then((service) => localeService = service),
    // Orientation lock (lightweight, run in parallel)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  ]);

  // Register services with GetX after initialization
  Get.put<ThemeService>(themeService, permanent: true);
  Get.put<LocaleService>(localeService, permanent: true);

  Get.put<ThemeController>(
    ThemeController(themeService: themeService),
    permanent: true,
  );

  await LocalizationService.init(localeService);
  unawaited(Get.updateLocale(LocalizationService.initialLocale));
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
        title: '360ghar stays',
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
