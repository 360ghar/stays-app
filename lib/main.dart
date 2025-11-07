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
import 'app/data/services/supabase_service.dart';
import 'app/utils/security/cert_pinning.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Default to dev if launched via lib/main.dart
  await dotenv.load(fileName: '.env.dev');
  AppConfig.setConfig(AppConfig.dev());

  // Optional certificate pinning when API_CERT_SHA256 is provided
  final pinsRaw = dotenv.env['API_CERT_SHA256'];
  if (pinsRaw != null && pinsRaw.trim().isNotEmpty) {
    final host = Uri.parse(AppConfig.I.apiBaseUrl).host;
    final pins = pinsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (pins.isNotEmpty) {
      HttpOverrides.global = PinningHttpOverrides(allowedPins: pins, host: host);
    }
  }

  // Ensure Supabase is ready before any repository or controller resolves it.
  final supabaseService = SupabaseService(
    url: AppConfig.I.supabaseUrl,
    anonKey: AppConfig.I.supabaseAnonKey,
  );
  await supabaseService.initialize();
  if (!Get.isRegistered<SupabaseService>()) {
    Get.put<SupabaseService>(supabaseService, permanent: true);
  }

  // Storage is initialized later by SplashController if needed

  final themeService = await Get.putAsync<ThemeService>(
    () async => ThemeService().init(),
    permanent: true,
  );

  // Locale service + load translations
  final localeService = await Get.putAsync<LocaleService>(
    () async => LocaleService().init(),
    permanent: true,
  );
  await LocalizationService.init(localeService);
  Get.updateLocale(LocalizationService.initialLocale);

  Get.put<ThemeController>(
    ThemeController(themeService: themeService),
    permanent: true,
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
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 250),
      );
    });
  }
}
