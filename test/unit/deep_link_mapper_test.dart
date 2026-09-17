import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/services/deep_link_service.dart';

/// Mapper tests for DeepLinkService._mapToInternalPath via the public
/// `mapToInternalPath` probe. Fixtures are backend-shaped share URLs
/// (`https://the360ghar.com/stays/<entity>/<id>`); no navigation, no network.
void main() {
  DeepLinkService createService() => DeepLinkService();

  group('valid IDs map to internal paths', () {
    test('namespaced listing URL maps to /listing/:id', () {
      final service = createService();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/stays/listing/abc123'),
        ),
        '/listing/abc123',
      );
    });

    test('bare listing URL (no stays prefix) also maps', () {
      final service = createService();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/listing/abc123'),
        ),
        '/listing/abc123',
      );
    });

    test('chat URL maps to /chat/:conversationId', () {
      final service = createService();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/stays/chat/conv-1_X'),
        ),
        '/chat/conv-1_X',
      );
    });

    test('IDs with dashes and underscores are accepted', () {
      final service = createService();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/stays/listing/aB0-_9'),
        ),
        '/listing/aB0-_9',
      );
    });
  });

  group('invalid IDs and paths return null', () {
    test('unknown entity returns null', () {
      final service = createService();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/stays/booking/42'),
        ),
        isNull,
      );
    });

    test('single-segment path returns null', () {
      final service = createService();
      expect(
        service.mapToInternalPath(Uri.parse('https://the360ghar.com/stays')),
        isNull,
      );
    });

    test('empty path returns null', () {
      final service = createService();
      expect(
        service.mapToInternalPath(Uri.parse('https://the360ghar.com/')),
        isNull,
      );
    });

    test('ID with illegal characters returns null', () {
      final service = createService();
      // Note: a '/' in the ID is a segment separator, so it can never
      // reach the validator as one ID — the first segment is used instead.
      for (final bad in ['bad id!', 'x@y', 'a.b', 'a+b=c']) {
        expect(
          service.mapToInternalPath(
            Uri.parse('https://the360ghar.com/stays/listing/$bad'),
          ),
          isNull,
          reason: 'ID "$bad" must be rejected',
        );
      }
    });

    test('over-long ID (>64 chars) returns null', () {
      final service = createService();
      final longId = List.filled(65, 'a').join();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/stays/listing/$longId'),
        ),
        isNull,
      );
    });

    test('empty ID segment returns null', () {
      final service = createService();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/stays/listing/'),
        ),
        isNull,
      );
    });

    test('chat IDs are validated the same way', () {
      final service = createService();
      expect(
        service.mapToInternalPath(
          Uri.parse('https://the360ghar.com/stays/chat/evil!id'),
        ),
        isNull,
      );
    });
  });
}
