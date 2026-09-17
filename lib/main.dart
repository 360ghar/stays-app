import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'core/boot/v2_boot.dart';
import 'core/providers/app_settings_providers.dart';
import 'l10n/localization_service.dart';
import 'app/data/services/locale_service.dart';
import 'app/data/services/theme_service.dart';
import 'app/data/services/supabase_service.dart';
import 'app/data/services/crash_reporting_service.dart';
import 'app/utils/security/cert_pinning.dart';
import 'app/utils/logger/app_logger.dart';
import 'app/utils/security/security_service.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Default to dev if launched via lib/main.dart
      await dotenv.load(fileName: '.env.dev');
      AppConfig.setConfig(AppConfig.dev());
      SecurityService.validateApiKeys();

      // Optional certificate pinning when API_CERT_SHA256 is provided
      final pinsRaw = dotenv.env['API_CERT_SHA256'];
      if (pinsRaw != null && pinsRaw.trim().isNotEmpty) {
        final host = Uri.parse(AppConfig.I.api.apiBaseUrl).host;
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

      // Supabase SDK init kicks off here and is awaited below before runApp.
      SupabaseService.supabaseServiceReady = SupabaseService(
        url: AppConfig.I.auth.supabaseUrl,
        publishableKey: AppConfig.I.auth.supabasePublishableKey,
      ).initialize();

      // Parallelize initialization of independent services for faster startup
      late ThemeService themeService;
      late LocaleService localeService;

      await Future.wait([
        // Supabase initialization (critical).
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

      // Theme/locale services are owned by Riverpod overrides below.

      // Load translations (depends on localeService)
      await LocalizationService.init(localeService);

      // V2 boot runs the canonical startup chain here.
      await ensureV2Bindings();

      runApp(
        ProviderScope(
          overrides: [
            themeServiceProvider.overrideWithValue(themeService),
            localeServiceProvider.overrideWithValue(localeService),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stackTrace) async {
      AppLogger.error('Uncaught zone error', error, stackTrace);
      // Degrades to a log when crash reporting is disabled/uninitialized.
      await CrashReportingService().recordError(
        error,
        stackTrace: stackTrace,
        fatal: true,
      );
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return buildV2App(
      title: '360ghar stays',
      themeMode: ref.watch(themeProvider),
      locale: ref.watch(localeProvider),
    );
  }
}
