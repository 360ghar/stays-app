import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:stays_app/app/utils/helpers/supabase_auth_error_mapper.dart';

void main() {
  group('mapSupabaseAuthError', () {
    test('maps invalid login credentials to product copy + 401', () {
      const err = supabase.AuthException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );
      final mapped = mapSupabaseAuthError(err);
      expect(mapped.message, AuthErrorMessages.invalidCredentials);
      expect(mapped.statusCode, 401);
    });

    test('maps OTP context invalid credentials to otp invalid', () {
      const err = supabase.AuthException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      );
      final mapped = mapSupabaseAuthError(err, context: AuthErrorContext.otp);
      expect(mapped.message, AuthErrorMessages.otpInvalid);
    });

    test('maps rate limit codes to 429', () {
      const err = supabase.AuthException(
        'rate limit exceeded',
        statusCode: '429',
        code: 'over_request_rate_limit',
      );
      final mapped = mapSupabaseAuthError(err);
      expect(mapped.message, AuthErrorMessages.rateLimited);
      expect(mapped.statusCode, 429);
    });

    test('maps email not confirmed', () {
      const err = supabase.AuthException(
        'Email not confirmed',
        statusCode: '400',
        code: 'email_not_confirmed',
      );
      final mapped = mapSupabaseAuthError(err);
      expect(mapped.message, AuthErrorMessages.unverified);
      expect(mapped.statusCode, 403);
    });

    test('never surfaces AuthException toString dump', () {
      const err = supabase.AuthException('Invalid login credentials');
      final mapped = mapSupabaseAuthError(err);
      expect(mapped.message.contains('AuthException('), isFalse);
      expect(mapped.message, AuthErrorMessages.invalidCredentials);
    });
  });
}
