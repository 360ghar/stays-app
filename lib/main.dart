import 'package:flutter/material.dart';
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
import 'app/data/services/storage_service.dart';
import 'app/data/services/push_notification_service.dart';
import 'app/data/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Default to dev if launched via lib/main.dart
  await dotenv.load(fileName: '.env.dev');
  AppConfig.setConfig(AppConfig.dev());

  // Ensure Supabase is ready before any repository or controller resolves it.
  final supabaseService = SupabaseService(
    url: AppConfig.I.supabaseUrl,
    anonKey: AppConfig.I.supabaseAnonKey,
  );
  await supabaseService.initialize();
  if (!Get.isRegistered<SupabaseService>()) {
    Get.put<SupabaseService>(supabaseService, permanent: true);
  }

  final storageService = Get.isRegistered<StorageService>()
      ? Get.find<StorageService>()
      : await Get.putAsync<StorageService>(
          () async => StorageService().initialize(),
          permanent: true,
        );

  if (!Get.isRegistered<PushNotificationService>()) {
    await Get.putAsync<PushNotificationService>(
      () async => PushNotificationService(storageService).init(),
      permanent: true,
    );
  }

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
