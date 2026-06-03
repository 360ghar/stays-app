import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/utils/services/token_service.dart';

void main() {
  group('TokenInfo.fromJson', () {
    test('uses current time when createdAt is missing', () {
      final before = DateTime.now();
      final token = TokenInfo.fromJson({
        'accessToken': 'token',
        'refreshToken': 'refresh',
      });
      final after = DateTime.now();

      expect(token.createdAt.isBefore(before), isFalse);
      expect(token.createdAt.isAfter(after), isFalse);
    });

    test('uses current time when createdAt is null', () {
      final before = DateTime.now();
      final token = TokenInfo.fromJson({
        'accessToken': 'token',
        'createdAt': null,
      });
      final after = DateTime.now();

      expect(token.createdAt.isBefore(before), isFalse);
      expect(token.createdAt.isAfter(after), isFalse);
    });

    test('parses createdAt when a valid ISO value is provided', () {
      const createdAt = '2025-01-01T10:30:00.000Z';
      final token = TokenInfo.fromJson({
        'accessToken': 'token',
        'createdAt': createdAt,
      });

      expect(token.createdAt.toUtc().toIso8601String(), createdAt);
    });
  });
}
