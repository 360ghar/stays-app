import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stays_app/config/api_config.dart';
import 'package:stays_app/config/auth_config.dart';
import 'package:stays_app/config/locale_config.dart';

/// App-wide environment configuration.
///
/// ## Value precedence (per key)
///
/// `--dart-define` (compile time) > `.env.<env>` file (runtime) > built-in
/// default. See [AppConfig.fromDotEnv].
///
/// ## Precedence test doc (how to verify, no code changes needed)
///
/// 1. Set a canary in `.env.dev`: `API_BASE_URL=https://dotenv-value.test`.
/// 2. Run with an override:
///    `flutter run -t lib/main_dev.dart
///    --dart-define=API_BASE_URL=https://define-value.test`.
/// 3. Expect `AppConfig.I.apiBaseUrl == 'https://define-value.test'`.
/// 4. Run without the define; expect the dotenv value.
/// 5. Remove the key from `.env.dev` and run without the define; expect
///    [MissingEnvironmentException] for a required key, or the built-in
///    default for an optional key (`ENABLE_ANALYTICS`, `DEFAULT_COUNTRY`).
///
/// ## Split proposal (comments only, not implemented)
///
/// Proposed: split this file into `env_loader.dart` (raw
/// define-over-dotenv map assembly + validation) and `app_config.dart`
/// (typed view over the resolved map). Rationale: precedence logic is
/// currently interleaved with the typed getters, which makes it hard to
/// unit-test precedence without loading dotenv. Do NOT implement until the
/// other workers' config touch-points land; resolution logic below is
/// intentionally unchanged.

/// Exception thrown when required environment variables are missing
class MissingEnvironmentException implements Exception {
  const MissingEnvironmentException({
    required this.missingVariables,
    required this.environment,
  });

  final List<String> missingVariables;
  final String environment;

  @override
  String toString() =>
      'MissingEnvironmentException: Missing required environment variables '
      'for $environment: ${missingVariables.join(', ')}. '
      'Please ensure your .env.$environment file contains all required variables.';
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.enableAnalytics = false,
    this.googleMapsApiKey,
    this.googleWebClientId,
    this.googleIosClientId,
    this.defaultCountry = 'IN',
  });

  final String environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final bool enableAnalytics;
  final String? googleMapsApiKey;

  /// Google OAuth Web client ID. On Android this is used as the
  /// `serverClientId` for the native Google Sign-In ID-token flow.
  final String? googleWebClientId;

  /// Google OAuth iOS client ID. On iOS this is used as the `clientId`
  /// for the native Google Sign-In ID-token flow.
  final String? googleIosClientId;

  /// ISO-3166 alpha-2 country code used for phone normalization when the user
  /// has not explicitly picked a country. Resolved from `DEFAULT_COUNTRY`
  /// with precedence: --dart-define > .env file > 'IN'.
  final String defaultCountry;

  /// Built-in fallback ISO-3166 alpha-2 country used when neither
  /// `--dart-define=DEFAULT_COUNTRY` nor the `.env` file provides one.
  static const String fallbackDefaultCountry = 'IN';

  /// Built-in fallback dial code used when [defaultCountry] is not present
  /// in [defaultCountryDialCodes].
  static const String fallbackDefaultDialCode = '+91';

  /// Dial code for [defaultCountry] (e.g. `+91` for `IN`), used by phone
  /// normalization as a fallback when no country is selected.
  ///
  /// The map below is intentionally tiny and is only a fallback; the source
  /// of truth for supported countries/dial codes lives with the country
  /// picker used by the auth flow.
  static const Map<String, String> defaultCountryDialCodes = <String, String>{
    'IN': '+91',
    'US': '+1',
    'GB': '+44',
    'AE': '+971',
    'SG': '+65',
    'AU': '+61',
    'CA': '+1',
    'MY': '+60',
  };

  /// Dial code for [defaultCountry]. Falls back to [fallbackDefaultDialCode]
  /// for countries not present in [defaultCountryDialCodes].
  String get defaultCountryDialCode =>
      defaultCountryDialCodes[defaultCountry] ?? fallbackDefaultDialCode;

  // ── Additive split: dipole views over the same fields ───────────────────
  // New code should prefer these sub-configs over the top-level fields:
  // - Network: `AppConfig.I.api` (ApiConfig: apiBaseUrl, enableAnalytics).
  //   Deprecation target for [apiBaseUrl] and [enableAnalytics].
  // - Auth: `AppConfig.I.auth` (AuthConfig: supabaseUrl,
  //   supabasePublishableKey, googleWebClientId, googleIosClientId,
  //   isGoogleSignInConfigured). Deprecation target for the matching fields.
  // - Locale: `AppConfig.I.locale` (LocaleConfig: defaultCountry,
  //   defaultCountryDialCode). Deprecation target for [defaultCountry] and
  //   [defaultCountryDialCode]. No caller changes required; these getters
  //   delegate to the existing fields.

  /// Network slice: mirrors [apiBaseUrl] and [enableAnalytics].
  ApiConfig get api =>
      ApiConfig(apiBaseUrl: apiBaseUrl, enableAnalytics: enableAnalytics);

  /// Auth slice: mirrors Supabase + Google Sign-In fields.
  AuthConfig get auth => AuthConfig(
    supabaseUrl: supabaseUrl,
    supabasePublishableKey: supabasePublishableKey,
    googleWebClientId: googleWebClientId,
    googleIosClientId: googleIosClientId,
  );

  /// Locale slice: mirrors [defaultCountry].
  LocaleConfig get locale => LocaleConfig(defaultCountry: defaultCountry);

  static late AppConfig _instance;

  static AppConfig get I => _instance;

  static void setConfig(AppConfig config) {
    _instance = config;
  }

  static AppConfig dev() => fromDotEnv(environment: 'dev');

  static AppConfig staging() => fromDotEnv(environment: 'staging');

  static AppConfig prod() => fromDotEnv(environment: 'prod');

  static bool get isProduction => I.environment == 'prod';
  static bool get isStaging => I.environment == 'staging';
  static bool get isDev => I.environment == 'dev';

  /// Validates that all required environment variables are present
  /// Throws [MissingEnvironmentException] if any are missing
  static void _validateEnvironment(
    Map<String, String> env,
    String environment,
  ) {
    final requiredVars = <String>['API_BASE_URL', 'SUPABASE_URL'];

    final missingVars = requiredVars
        .where((key) => env[key] == null || env[key]!.isEmpty)
        .toList();

    final publishableKey = env['SUPABASE_PUBLISHABLE_KEY'];
    if (publishableKey == null || publishableKey.isEmpty) {
      missingVars.add('SUPABASE_PUBLISHABLE_KEY');
    }

    if (missingVars.isNotEmpty) {
      throw MissingEnvironmentException(
        missingVariables: missingVars,
        environment: environment,
      );
    }

    // Additional validation: ensure values are not placeholders. Covers the
    // required vars and the Supabase publishable key.
    final keysToCheck = <String>[...requiredVars, 'SUPABASE_PUBLISHABLE_KEY'];
    for (final key in keysToCheck) {
      final value = env[key] ?? '';
      if (isPlaceholderValue(value)) {
        throw MissingEnvironmentException(
          missingVariables: ['$key (contains placeholder value)'],
          environment: environment,
        );
      }
    }
  }

  /// Regex fragments matching unfilled template values (e.g. `YOUR_*`,
  /// `*PLACEHOLDER*`, `<template>`, `your-*-key`). A value matching any
  /// entry is treated the same as a missing value by [_validateEnvironment].
  static const List<String> placeholderValuePatterns = <String>[
    r'YOUR_.*',
    r'.*PLACEHOLDER.*',
    r'<.*>',
    r'^your-.*-key$',
  ];

  /// True when [value] looks like an unfilled placeholder (see
  /// [placeholderValuePatterns]) or is blank. Shared by
  /// [_validateEnvironment] and [SupabaseService] so the two never disagree.
  static bool isPlaceholderValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return true;
    for (final p in placeholderValuePatterns) {
      if (RegExp(p, caseSensitive: false).hasMatch(trimmed)) return true;
    }
    return false;
  }

  static AppConfig fromDotEnv({required String environment}) {
    // ── Effective-value resolution (computed once) ─────────────────────────
    // Precedence: --dart-define (compile-time) WINS, then the bundled .env
    // file (runtime, loaded by the entrypoint via `dotenv.load`), then the
    // built-in default. Defines are baked in at build time (const
    // String.fromEnvironment) so CI/prod builds never depend on a key that
    // was stripped from the bundled .env file.
    final apiBaseUrl =
        _define('API_BASE_URL') ?? _nullIfEmpty(dotenv.env['API_BASE_URL']);
    final supabaseUrl =
        _define('SUPABASE_URL') ?? _nullIfEmpty(dotenv.env['SUPABASE_URL']);
    final supabasePublishableKey =
        _define('SUPABASE_PUBLISHABLE_KEY') ??
        _nullIfEmpty(dotenv.env['SUPABASE_PUBLISHABLE_KEY']);
    // Support either GOOGLE_MAPS_API_KEY or GOOGLE_PLACES_API_KEY. Within
    // each tier (define vs dotenv) the MAPS alias wins, and any define beats
    // any dotenv value.
    final googleMapsApiKey =
        _define('GOOGLE_MAPS_API_KEY') ??
        _define('GOOGLE_PLACES_API_KEY') ??
        _nullIfEmpty(dotenv.env['GOOGLE_MAPS_API_KEY']) ??
        _nullIfEmpty(dotenv.env['GOOGLE_PLACES_API_KEY']);
    final googleWebClientId =
        _define('GOOGLE_WEB_CLIENT_ID') ??
        _nullIfEmpty(dotenv.env['GOOGLE_WEB_CLIENT_ID']);
    final googleIosClientId =
        _define('GOOGLE_IOS_CLIENT_ID') ??
        _nullIfEmpty(dotenv.env['GOOGLE_IOS_CLIENT_ID']);
    final enableAnalyticsRaw =
        _define('ENABLE_ANALYTICS') ??
        _nullIfEmpty(dotenv.env['ENABLE_ANALYTICS']) ??
        (environment == 'prod' ? 'true' : 'false');
    final defaultCountry =
        (_define('DEFAULT_COUNTRY') ??
                _nullIfEmpty(dotenv.env['DEFAULT_COUNTRY']) ??
                fallbackDefaultCountry)
            .toUpperCase();

    // Validate the EFFECTIVE values (define over dotenv), not the raw dotenv
    // map, so a define can satisfy a key that is absent from the .env file.
    _validateEnvironment(<String, String>{
      'API_BASE_URL': apiBaseUrl ?? '',
      'SUPABASE_URL': supabaseUrl ?? '',
      'SUPABASE_PUBLISHABLE_KEY': supabasePublishableKey ?? '',
    }, environment);

    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl!,
      supabaseUrl: supabaseUrl!,
      supabasePublishableKey: supabasePublishableKey!,
      enableAnalytics: enableAnalyticsRaw == 'true',
      googleMapsApiKey: googleMapsApiKey,
      // Optional Google Sign-In client IDs (empty/missing => Google disabled).
      googleWebClientId: googleWebClientId,
      googleIosClientId: googleIosClientId,
      defaultCountry: defaultCountry,
    );
  }

  /// Compile-time `--dart-define` values. `String.fromEnvironment` only reads
  /// real values in const contexts, so each supported key is captured once in
  /// this const table and looked up at runtime by [_define].
  static const Map<String, String> _defines = <String, String>{
    'API_BASE_URL': String.fromEnvironment('API_BASE_URL'),
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_PUBLISHABLE_KEY': String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    'GOOGLE_MAPS_API_KEY': String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
    'GOOGLE_PLACES_API_KEY': String.fromEnvironment('GOOGLE_PLACES_API_KEY'),
    'GOOGLE_WEB_CLIENT_ID': String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    'GOOGLE_IOS_CLIENT_ID': String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    'ENABLE_ANALYTICS': String.fromEnvironment('ENABLE_ANALYTICS'),
    'DEFAULT_COUNTRY': String.fromEnvironment('DEFAULT_COUNTRY'),
  };

  /// Returns the build-time `--dart-define` value for [key], or null when the
  /// define is absent or empty. Compile-time defines take precedence over the
  /// bundled .env files (see [fromDotEnv]).
  static String? _define(String key) {
    final value = _defines[key] ?? '';
    if (value.isEmpty) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _nullIfEmpty(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Whether native Google Sign-In is configured (at least the web client ID
  /// for the Android serverClientId / Supabase audience).
  bool get isGoogleSignInConfigured =>
      (googleWebClientId != null && googleWebClientId!.isNotEmpty) ||
      (googleIosClientId != null && googleIosClientId!.isNotEmpty);
}
