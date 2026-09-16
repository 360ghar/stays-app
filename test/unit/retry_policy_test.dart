import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:stays_app/app/data/providers/base_provider.dart';
import 'package:stays_app/app/utils/exceptions/network_exceptions.dart';

void main() {
  group('shouldRetryRequest', () {
    test('retries GET on transient status codes', () {
      for (final status in [408, 429, 500, 502, 503, 504]) {
        expect(
          shouldRetryRequest(
            method: 'GET',
            statusCode: status,
            attempt: 0,
            transportFailure: TransportFailureKind.none,
          ),
          isTrue,
          reason: 'GET $status should retry',
        );
      }
    });

    test('never retries GET on non-transient status codes', () {
      for (final status in [400, 401, 403, 404, 422]) {
        expect(
          shouldRetryRequest(
            method: 'GET',
            statusCode: status,
            attempt: 0,
            transportFailure: TransportFailureKind.none,
          ),
          isFalse,
          reason: 'GET $status should not retry',
        );
      }
    });

    test('never retries POST/PUT/DELETE on any HTTP status', () {
      for (final method in ['POST', 'PUT', 'DELETE']) {
        for (final status in [408, 429, 500, 502, 503, 504]) {
          expect(
            shouldRetryRequest(
              method: method,
              statusCode: status,
              attempt: 0,
              transportFailure: TransportFailureKind.none,
            ),
            isFalse,
            reason: '$method $status must not retry (duplicate-write risk)',
          );
        }
      }
    });

    test('retries never-delivered requests for ANY method', () {
      for (final method in ['GET', 'POST', 'PUT', 'DELETE']) {
        expect(
          shouldRetryRequest(
            method: method,
            attempt: 0,
            transportFailure: TransportFailureKind.neverSent,
          ),
          isTrue,
          reason: '$method with neverSent must retry',
        );
      }
    });

    test('retries possibly-sent requests only for idempotent methods', () {
      expect(
        shouldRetryRequest(
          method: 'GET',
          attempt: 0,
          transportFailure: TransportFailureKind.possiblySent,
        ),
        isTrue,
      );
      for (final method in ['POST', 'PUT', 'DELETE']) {
        expect(
          shouldRetryRequest(
            method: method,
            attempt: 0,
            transportFailure: TransportFailureKind.possiblySent,
          ),
          isFalse,
          reason: '$method with possiblySent must not retry',
        );
      }
    });

    test('respects the attempt budget (1 initial + 2 retries)', () {
      expect(
        shouldRetryRequest(
          method: 'GET',
          statusCode: 503,
          attempt: 2,
          transportFailure: TransportFailureKind.none,
        ),
        isFalse,
      );
      expect(
        shouldRetryRequest(
          method: 'GET',
          statusCode: 503,
          attempt: 1,
          transportFailure: TransportFailureKind.none,
        ),
        isTrue,
      );
    });
  });

  group('classifyTransportFailure', () {
    test('classifies TimeoutException as possiblySent', () {
      expect(
        classifyTransportFailure(TimeoutException('t')),
        TransportFailureKind.possiblySent,
      );
    });

    test('classifies connection-refused text as neverSent', () {
      expect(
        classifyTransportFailure(
          Exception('SocketException: Connection refused (OS Error: ...)'),
        ),
        TransportFailureKind.neverSent,
      );
      expect(
        classifyTransportFailure(
          Exception('Failed host lookup: api.360ghar.com'),
        ),
        TransportFailureKind.neverSent,
      );
    });

    test('classifies timeout text as possiblySent', () {
      expect(
        classifyTransportFailure(Exception('Connection timed out after 30s')),
        TransportFailureKind.possiblySent,
      );
    });

    test('defaults unknown thrown errors to possiblySent', () {
      expect(
        classifyTransportFailure(StateError('boom')),
        TransportFailureKind.possiblySent,
      );
    });
  });
}
