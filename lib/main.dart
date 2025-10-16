import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'l10n/localization_service.dart';
import 'app/data/services/locale_service.dart';
import 'app/ui/theme/app_theme.dart';
import 'app/data/services/theme_service.dart';
import 'app/controllers/settings/theme_controller.dart';
import 'app/data/services/storage_service.dart';
import 'app/data/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prepare the local storage backing the remember-me feature before bindings run.
  const rememberMeBox = 'auth_preferences';
  const rememberMeFlagKey = 'remember_me';
  const rememberedAccessTokenKey = 'remembered_access_token';

  await GetStorage.init(rememberMeBox);
  final authPrefs = GetStorage(rememberMeBox);
  final bool rememberMeEnabled =
      authPrefs.read<bool>(rememberMeFlagKey) ?? false;
  final String? rememberedAccessToken =
      authPrefs.read<String>(rememberedAccessTokenKey);
  final String initialRoute =
      rememberMeEnabled && (rememberedAccessToken?.isNotEmpty ?? false)
          ? Routes.home
          : AppPages.initial;

  // Default to dev if launched via lib/main.dart
  await dotenv.load(fileName: '.env.dev');
  AppConfig.setConfig(AppConfig.dev());

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

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialRoute});

  final String initialRoute;

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
        initialRoute: initialRoute,
        getPages: AppPages.routes,
        debugShowCheckedModeBanner: false,
        defaultTransition: Transition.cupertino,
        transitionDuration: const Duration(milliseconds: 250),
      );
    });
  }
}
