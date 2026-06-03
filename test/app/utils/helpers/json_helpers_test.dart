import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/utils/helpers/json_helpers.dart';

void main() {
  group('JsonHelpers datetime helpers', () {
    test('parses naive timestamps as UTC', () {
      final parsed = JsonHelpers.getDateTime('2026-03-12T10:15:30');

      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
      expect(parsed.toIso8601String(), '2026-03-12T10:15:30.000Z');
    });

    test('parses epoch seconds as UTC', () {
      final parsed = JsonHelpers.getDateTime(1710238530);

      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
    });

    test('serializes UTC instants and date-only values', () {
      final instant = DateTime.parse('2026-03-12T10:15:30+05:30');

      expect(JsonHelpers.toUtcIso8601(instant), '2026-03-12T04:45:30.000Z');
      expect(
        JsonHelpers.toDateOnly(DateTime(2026, 3, 12, 23, 59)),
        '2026-03-12',
      );
    });
  });
}
