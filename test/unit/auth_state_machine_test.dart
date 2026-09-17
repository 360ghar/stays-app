import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';

/// State-machine tests for the identifier-first login flow
/// (`POST /api/v1/auth/identifier-status` -> password screen vs OTP-first).
///
/// Fixtures use the backend's snake_case shape
/// (`exists`, `verified`, `has_password`, `channel`, `next_step`).
/// `resolveLoginStep` mirrors the routing rule the AuthController applies to
/// [IdentifierStatus]; no repository, no Supabase, no navigation.
String resolveLoginStep(IdentifierStatus status) {
  if (!status.exists) return 'otp-signup';
  if (!status.verified) return 'otp-verify';
  if (status.isPasswordStep && status.hasPassword) return 'password';
  return 'otp';
}

void main() {
  group('IdentifierStatus parsing (backend-shaped fixtures)', () {
    test('password account parses with password next step', () {
      final status = IdentifierStatus.fromJson({
        'exists': true,
        'verified': true,
        'has_password': true,
        'channel': 'email',
        'next_step': 'password',
      });
      expect(status.exists, isTrue);
      expect(status.verified, isTrue);
      expect(status.hasPassword, isTrue);
      expect(status.channel, 'email');
      expect(status.nextStep, 'password');
      expect(status.isPasswordStep, isTrue);
      expect(status.isOtpStep, isFalse);
      expect(status.isEmail, isTrue);
    });

    test('passwordless phone account parses with otp next step', () {
      final status = IdentifierStatus.fromJson({
        'exists': true,
        'verified': true,
        'has_password': false,
        'channel': 'phone',
        'next_step': 'otp',
      });
      expect(status.isOtpStep, isTrue);
      expect(status.isPhone, isTrue);
    });

    test('missing keys default to channel=email, next_step=otp', () {
      final status = IdentifierStatus.fromJson({});
      expect(status.exists, isFalse);
      expect(status.verified, isFalse);
      expect(status.hasPassword, isFalse);
      expect(status.channel, 'email');
      expect(status.nextStep, 'otp');
      expect(status.isOtpStep, isTrue);
    });
  });

  group('resolveLoginStep', () {
    test('verified password account -> password screen', () {
      expect(
        resolveLoginStep(
          IdentifierStatus.fromJson({
            'exists': true,
            'verified': true,
            'has_password': true,
            'channel': 'email',
            'next_step': 'password',
          }),
        ),
        'password',
      );
    });

    test('verified passwordless account -> otp screen', () {
      expect(
        resolveLoginStep(
          IdentifierStatus.fromJson({
            'exists': true,
            'verified': true,
            'has_password': false,
            'channel': 'phone',
            'next_step': 'otp',
          }),
        ),
        'otp',
      );
    });

    test('unknown identifier -> otp signup screen', () {
      expect(
        resolveLoginStep(
          IdentifierStatus.fromJson({
            'exists': false,
            'verified': false,
            'has_password': false,
            'channel': 'email',
            'next_step': 'otp',
          }),
        ),
        'otp-signup',
      );
    });

    test('unverified identifier -> otp verify screen', () {
      expect(
        resolveLoginStep(
          IdentifierStatus.fromJson({
            'exists': true,
            'verified': false,
            'has_password': true,
            'channel': 'email',
            'next_step': 'otp',
          }),
        ),
        'otp-verify',
      );
    });

    test('password next_step without a stored password falls back to otp', () {
      // Defensive: a stale backend hint must never strand the user on a
      // password screen for an account that has no password.
      expect(
        resolveLoginStep(
          const IdentifierStatus(
            exists: true,
            verified: true,
            hasPassword: false,
            channel: 'email',
            nextStep: 'password',
          ),
        ),
        'otp',
      );
    });
  });
}
