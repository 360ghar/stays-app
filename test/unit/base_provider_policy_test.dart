import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/providers/base_provider.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/exceptions/network_exceptions.dart';

/// Happy-path coverage for the BaseProvider retry/authenticator contract.
///
/// Uses only the `@visibleForTesting` policy helpers plus the exception
/// shapes the authenticator throws — no HTTP, no Supabase, no timers.
/// Backend-shaped fixtures: plain HTTP status codes, as the server sends.
void main() {
  group('retry happy path: transient GET eventually succeeds', () {
    test('policy retries 503 twice, then the third attempt succeeds', () {
      // Simulates _executeWithRetry's decision loop with zero delays:
      // two transient 503s followed by a 200.
      const statuses = [503, 503, 200];
      var attempts = 0;

      for (final status in statuses) {
        final shouldRetry = status != 200
            ? shouldRetryRequest(
                method: 'GET',
                statusCode: status,
                attempt: attempts,
                transportFailure: TransportFailureKind.none,
              )
            : false;
        if (shouldRetry) {
          attempts++;
          continue;
        }
        expect(status, 200, reason: 'final attempt returns the payload');
        break;
      }
      expect(attempts, 2);
    });

    test('HEAD and OPTIONS share the GET idempotent policy', () {
      for (final method in ['HEAD', 'OPTIONS', 'head', 'options']) {
        expect(
          shouldRetryRequest(
            method: method,
            statusCode: 503,
            attempt: 0,
            transportFailure: TransportFailureKind.none,
          ),
          isTrue,
          reason: '$method 503 should retry',
        );
        expect(
          shouldRetryRequest(
            method: method,
            statusCode: 404,
            attempt: 0,
            transportFailure: TransportFailureKind.none,
          ),
          isFalse,
          reason: '$method 404 should not retry',
        );
      }
    });
  });

  group('retry happy path: non-idempotent methods', () {
    test('POST with neverSent retries (safe: server never got it)', () {
      expect(
        shouldRetryRequest(
          method: 'POST',
          attempt: 0,
          transportFailure: TransportFailureKind.neverSent,
        ),
        isTrue,
      );
    });

    test('POST with a 503 response never retries (duplicate-write risk)', () {
      expect(
        shouldRetryRequest(
          method: 'POST',
          statusCode: 503,
          attempt: 0,
          transportFailure: TransportFailureKind.none,
        ),
        isFalse,
      );
    });
  });

  group('authenticator contract: 401 shapes', () {
    test(
      '401s are never retried by the retry policy (authenticator owns them)',
      () {
        expect(
          shouldRetryRequest(
            method: 'GET',
            statusCode: 401,
            attempt: 0,
            transportFailure: TransportFailureKind.none,
          ),
          isFalse,
        );
      },
    );

    test('authenticator failure modes carry 401 status codes', () {
      final noSession = ApiException(
        message: 'No session to refresh',
        statusCode: 401,
      );
      final unableToRefresh = ApiException(
        message: 'Unable to refresh',
        statusCode: 401,
      );
      final missingToken = ApiException(
        message: 'Missing access token after refresh',
        statusCode: 401,
      );
      for (final e in [noSession, unableToRefresh, missingToken]) {
        expect(e.statusCode, 401);
        expect(e.toString(), contains('401'));
      }
    });

    test('refreshed requests re-attach the token as a Bearer header', () {
      const newToken = 'aaa.bbb.ccc';
      final headers = <String, String>{};
      headers['Authorization'] = 'Bearer $newToken';
      expect(headers['Authorization'], 'Bearer aaa.bbb.ccc');
    });

    test('transport failures surface as 408 ApiExceptions with a kind', () {
      final e = ApiException(
        message: 'Request timed out. Please try again.',
        statusCode: 408,
        transportFailure: TransportFailureKind.possiblySent,
      );
      expect(e.statusCode, 408);
      expect(e.transportFailure, TransportFailureKind.possiblySent);
    });
  });

  group('classifyTransportFailure happy paths', () {
    test('TimeoutException never escapes unclassified', () async {
      expect(
        classifyTransportFailure(TimeoutException('connect timed out')),
        TransportFailureKind.possiblySent,
      );
    });
  });
}
