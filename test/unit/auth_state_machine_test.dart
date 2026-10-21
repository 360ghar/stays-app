import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/models/wire_enums.dart';
import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';

/// Parsing tests for `POST /api/v1/auth/identifier-status`.
///
/// Fixtures use the backend's snake_case shape
/// (`exists`, `verified`, `has_password`, `channel`, `next_step`).
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
      expect(status.channel, IdentifierChannel.email);
      expect(status.nextStep, IdentifierNextStep.password);
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

    test('missing or unknown channel and next_step read as null', () {
      final empty = IdentifierStatus.fromJson({});
      expect(empty.exists, isFalse);
      expect(empty.verified, isFalse);
      expect(empty.hasPassword, isFalse);
      expect(empty.channel, isNull);
      expect(empty.nextStep, isNull);
      expect(empty.isOtpStep, isFalse);
      expect(empty.isPasswordStep, isFalse);

      final unknown = IdentifierStatus.fromJson({
        'exists': true,
        'channel': 'carrier_pigeon',
        'next_step': 'magic',
      });
      expect(unknown.channel, isNull);
      expect(unknown.nextStep, isNull);
    });
  });
}
