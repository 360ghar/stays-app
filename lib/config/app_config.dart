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
    required this.supabaseAnonKey,
    this.enableAnalytics = false,
    this.googleMapsApiKey,
    this.googleWebClientId,
    this.googleIosClientId,
  });

  final String environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableAnalytics;
  final String? googleMapsApiKey;

  /// Google OAuth Web client ID. On Android this is used as the
  /// `serverClientId` for the native Google Sign-In ID-token flow.
  final String? googleWebClientId;

  /// Google OAuth iOS client ID. On iOS this is used as the `clientId`
  /// for the native Google Sign-In ID-token flow.
  final String? googleIosClientId;

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

    final publishableKey =
        env['SUPABASE_PUBLISHABLE_KEY'] ?? env['SUPABASE_ANON_KEY'];
    if (publishableKey == null || publishableKey.isEmpty) {
      missingVars.add('SUPABASE_PUBLISHABLE_KEY');
    }

    if (missingVars.isNotEmpty) {
      throw MissingEnvironmentException(
        missingVariables: missingVars,
        environment: environment,
      );
    }

    // Additional validation: ensure values are not placeholders
    final placeholderPatterns = [
      RegExp(r'YOUR_.*', caseSensitive: false),
      RegExp(r'PLACEHOLDER', caseSensitive: false),
      RegExp(r'<.*>'),
    ];

    for (final key in requiredVars) {
      final value = env[key] ?? '';
      for (final pattern in placeholderPatterns) {
        if (pattern.hasMatch(value)) {
          throw MissingEnvironmentException(
            missingVariables: ['$key (contains placeholder value)'],
            environment: environment,
          );
        }
      }
    }
  }

  static AppConfig fromDotEnv({required String environment}) {
    final env = dotenv.env;

    // Validate environment variables before proceeding
    _validateEnvironment(env, environment);

    return AppConfig(
      environment: environment,
      apiBaseUrl: env['API_BASE_URL']!,
      supabaseUrl: env['SUPABASE_URL']!,
      supabaseAnonKey:
          env['SUPABASE_PUBLISHABLE_KEY'] ?? env['SUPABASE_ANON_KEY']!,
      enableAnalytics:
          (env['ENABLE_ANALYTICS'] ??
              (environment == 'prod' ? 'true' : 'false')) ==
          'true',
      // Support either GOOGLE_MAPS_API_KEY or GOOGLE_PLACES_API_KEY
      googleMapsApiKey:
          env['GOOGLE_MAPS_API_KEY'] ?? env['GOOGLE_PLACES_API_KEY'],
      // Optional Google Sign-In client IDs (empty/missing => Google disabled).
      googleWebClientId: _nullIfEmpty(env['GOOGLE_WEB_CLIENT_ID']),
      googleIosClientId: _nullIfEmpty(env['GOOGLE_IOS_CLIENT_ID']),
    );
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
