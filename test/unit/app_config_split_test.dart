import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/config/app_config.dart';

void main() {
  group('AppConfig additive split', () {
    test('api/auth/locale getters mirror top-level fields', () {
      const config = AppConfig(
        environment: 'dev',
        apiBaseUrl: 'https://api.test',
        supabaseUrl: 'https://supabase.test',
        supabasePublishableKey: 'key-test',
        enableAnalytics: true,
        googleWebClientId: 'web-id',
        googleIosClientId: 'ios-id',
        defaultCountry: 'US',
      );

      expect(config.api.apiBaseUrl, config.apiBaseUrl);
      expect(config.api.enableAnalytics, config.enableAnalytics);
      expect(config.auth.supabaseUrl, config.supabaseUrl);
      expect(config.auth.supabasePublishableKey, config.supabasePublishableKey);
      expect(config.auth.googleWebClientId, config.googleWebClientId);
      expect(config.auth.googleIosClientId, config.googleIosClientId);
      expect(
        config.auth.isGoogleSignInConfigured,
        config.isGoogleSignInConfigured,
      );
      expect(config.locale.defaultCountry, config.defaultCountry);
      expect(
        config.locale.defaultCountryDialCode,
        config.defaultCountryDialCode,
      );
    });

    test('google-disabled + unknown-country fallbacks mirror', () {
      const config = AppConfig(
        environment: 'dev',
        apiBaseUrl: 'https://api.test',
        supabaseUrl: 'https://supabase.test',
        supabasePublishableKey: 'key-test',
        defaultCountry: 'ZZ',
      );

      expect(config.isGoogleSignInConfigured, isFalse);
      expect(config.auth.isGoogleSignInConfigured, isFalse);
      expect(config.defaultCountryDialCode, AppConfig.fallbackDefaultDialCode);
      expect(
        config.locale.defaultCountryDialCode,
        AppConfig.fallbackDefaultDialCode,
      );
    });
  });
}
