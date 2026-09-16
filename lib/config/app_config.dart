import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  /// Dial code for [defaultCountry] (e.g. `+91` for `IN`), used by phone
  /// normalization as a fallback when no country is selected.
  ///
  /// The map below is intentionally tiny and is only a fallback; the source
  /// of truth for supported countries/dial codes lives with the country
  /// picker used by the auth flow.
  static const Map<String, String> _defaultCountryDialCodes = <String, String>{
    'IN': '+91',
    'US': '+1',
    'GB': '+44',
    'AE': '+971',
    'SG': '+65',
    'AU': '+61',
    'CA': '+1',
    'MY': '+60',
  };

  /// Dial code for [defaultCountry]. Falls back to `+91` for countries not
  /// present in the tiny map above.
  String get defaultCountryDialCode =>
      _defaultCountryDialCodes[defaultCountry] ?? '+91';

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

  /// True when [value] looks like an unfilled placeholder (e.g. `YOUR_*`,
  /// `*PLACEHOLDER*`, `<template>`, or a blank string). Shared by
  /// [_validateEnvironment] and [SupabaseService] so the two never disagree.
  static bool isPlaceholderValue(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return true;
    const patterns = <String>[
      r'YOUR_.*',
      r'.*PLACEHOLDER.*',
      r'<.*>',
      r'^your-.*-key$',
    ];
    for (final p in patterns) {
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
                'IN')
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
