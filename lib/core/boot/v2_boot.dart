import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:stays_app/app/data/services/crash_reporting_service.dart';
import 'package:stays_app/app/data/services/image_prefetch_service.dart';
import 'package:stays_app/app/data/services/property_cache_service.dart';
import 'package:stays_app/app/data/services/remember_me_service.dart';
import 'package:stays_app/app/data/services/storage_service.dart';
import 'package:stays_app/app/ui/theme/app_theme.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/l10n/localization_service.dart';

/// Shared v2 boot used by every entry point (dev / staging / prod).
///
/// Runs the canonical startup chain once before [runApp]: [StorageService]
/// first (TokenService and providers await [StorageService.ready]), then the
/// independent inits fire-and-forget. All services are shared singletons that
/// construct on first use, so there is no DI graph to install.
Future<void> ensureV2Bindings() async {
  await StorageService().initialize();
  unawaited(CrashReportingService().init());
  unawaited(RememberMeService().init());
  unawaited(PropertyCacheService().init());
  unawaited(ImagePrefetchService().init());
}

/// V2 [MaterialApp.router]. Theme and locale follow the same services as
/// the legacy boot; only routing and state management differ.
Widget buildV2App({
  required String title,
  required ThemeMode themeMode,
  required Locale locale,
}) {
  return MaterialApp.router(
    title: title,
    theme: StayTokens.lightTheme(),
    darkTheme: AppTheme.darkTheme,
    themeMode: themeMode,
    routerConfig: v2RouterInstance(),
    locale: locale,
    supportedLocales: LocalizationService.locales,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    debugShowCheckedModeBanner: false,
  );
}
