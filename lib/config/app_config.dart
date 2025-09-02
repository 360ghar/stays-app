import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String environment;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableAnalytics;

  static late AppConfig _instance;

  static AppConfig get I => _instance;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.enableAnalytics = false,
  });

  static void setConfig(AppConfig config) {
    _instance = config;
  }

  static AppConfig dev() => fromDotEnv(environment: 'dev');

  static AppConfig staging() => fromDotEnv(environment: 'staging');

  static AppConfig prod() => fromDotEnv(environment: 'prod');

  static bool get isProduction => I.environment == 'prod';
  static bool get isStaging => I.environment == 'staging';
  static bool get isDev => I.environment == 'dev';

  static AppConfig fromDotEnv({required String environment}) {
    final env = dotenv.env;
    return AppConfig(
      environment: environment,
      apiBaseUrl: env['API_BASE_URL'] ?? 'https://api.dev.360ghar.com',
      supabaseUrl: env['SUPABASE_URL'] ?? 'https://YOUR_DEV_SUPABASE_URL',
      supabaseAnonKey: env['SUPABASE_ANON_KEY'] ?? 'YOUR_DEV_SUPABASE_ANON_KEY',
      enableAnalytics: (env['ENABLE_ANALYTICS'] ?? (environment == 'prod' ? 'true' : 'false')) == 'true',
    );
  }
}
