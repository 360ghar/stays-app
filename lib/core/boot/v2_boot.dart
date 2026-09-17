import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:stays_app/app/bindings/initial_binding.dart';
import 'package:stays_app/app/ui/theme/app_theme.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/l10n/localization_service.dart';

/// Shared v2 boot used by every entry point (dev / staging / prod).
///
/// V2 has no GetMaterialApp to run [InitialBinding], so [ensureV2Bindings]
/// runs the canonical DI graph once before [runApp].
void ensureV2Bindings() {
  InitialBinding().dependencies();
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
