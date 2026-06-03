import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/utils/extensions/dynamic_extensions.dart';

void main() {
  group('parseBool', () {
    test('returns true for truthy string tokens', () {
      expect(parseBool('true', fallback: false), isTrue);
      expect(parseBool('1', fallback: false), isTrue);
      expect(parseBool('YES', fallback: false), isTrue);
    });

    test('returns false for falsy string tokens', () {
      expect(parseBool('false', fallback: true), isFalse);
      expect(parseBool('0', fallback: true), isFalse);
      expect(parseBool('No', fallback: true), isFalse);
    });

    test('returns fallback for unknown string tokens', () {
      expect(parseBool('maybe', fallback: true), isTrue);
      expect(parseBool('maybe', fallback: false), isFalse);
    });
  });
}
