import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'core/boot/v2_boot.dart';
import 'core/router/app_router.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'l10n/localization_service.dart';
import 'app/data/services/locale_service.dart';
import 'app/ui/theme/app_theme.dart';
import 'app/data/services/theme_service.dart';
import 'app/data/services/supabase_service.dart';
import 'app/data/services/crash_reporting_service.dart';
import 'features/settings/controllers/theme_controller.dart';
import 'app/utils/logger/app_logger.dart';
import 'app/utils/security/security_service.dart';
import 'core/boot/common_boot.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await dotenv.load(fileName: '.env.dev');
      AppConfig.setConfig(AppConfig.dev());
      ensureCommonBindings();
      // Validate high-level API keys (pure static: no GetX construction pre-binding)
      SecurityService.validateApiKeys();

      // Supabase is owned by InitialBinding.putAsync (single source of truth
      // for the registered client). We publish the init future here so the
      // binding can await the same work, avoiding a double `Supabase.initialize`.
      SupabaseService.supabaseServiceReady = SupabaseService(
        url: AppConfig.I.auth.supabaseUrl,
        publishableKey: AppConfig.I.auth.supabasePublishableKey,
      ).initialize();
      // Optional certificate pinning (shared helper; see common_boot.dart).
      applyCertPinning(log: true);

      // Parallelize initialization of independent services for faster startup
      late ThemeService themeService;
      late LocaleService localeService;

      await Future.wait([
        // Supabase initialization (critical) — shared with the binding.
        SupabaseService.supabaseServiceReady!,
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

      // Register services with GetX after initialization. SupabaseService is
      // registered by InitialBinding — see notes above.
      Get.put<ThemeService>(themeService, permanent: true);
      Get.put<LocaleService>(localeService, permanent: true);

      Get.put<ThemeController>(
        ThemeController(themeService: themeService),
        permanent: true,
      );

      await LocalizationService.init(localeService);
      unawaited(Get.updateLocale(LocalizationService.initialLocale));
      AppLogger.info(
        'Localization initialized with locale: ${LocalizationService.initialLocale}',
      );

      if (useV2Router) {
        ensureV2Bindings();
      }

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stackTrace) async {
      AppLogger.error('Uncaught zone error', error, stackTrace);
      if (Get.isRegistered<CrashReportingService>()) {
        await Get.find<CrashReportingService>().recordError(
          error,
          stackTrace: stackTrace,
          fatal: true,
        );
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final currentLocale = Get.locale ?? LocalizationService.initialLocale;
      if (useV2Router) {
        return buildV2App(
          title: '360ghar stays (Dev)',
          themeMode: themeController.themeMode.value,
          locale: currentLocale,
        );
      }
      return GetMaterialApp(
        title: '360ghar stays (Dev)',
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
