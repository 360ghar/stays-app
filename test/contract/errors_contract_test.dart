// Contract tests for error bodies: every non-2xx body is
// {"error": {"code", "message", "details"}}. A 422 lists its field errors in
// details.fields as [{field, msg, type}].

import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/providers/base_provider.dart';
import 'package:stays_app/app/data/providers/users_provider.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/services/error_service.dart';

import 'support/wire.dart';

ApiResponse _response(Object? body, int status, {String? statusMessage}) {
  return ApiResponse(
    statusCode: status,
    statusMessage: statusMessage,
    data: body,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(useTestConfig);

  final errors = fixture('errors');
  final service = ErrorService();

  test('a 401 envelope gives its code and message', () {
    final error = service.toApiException(
      _response(errors['unauthorized'], 401),
    );
    expect(error.statusCode, 401);
    expect(error.code, 'TOKEN_INVALID');
    expect(error.message, 'The token is not valid.');
    expect(error.fieldErrors, isEmpty);
  });

  test('a 422 envelope lists its field errors', () {
    final error = service.toApiException(_response(errors['validation'], 422));
    expect(error.statusCode, 422);
    expect(error.code, 'VALIDATION_ERROR');
    expect(error.fieldErrors, hasLength(2));
    expect(error.fieldErrors.first.field, 'body.primary_guest_email');
    expect(error.fieldErrors.first.name, 'primary_guest_email');
    expect(error.fieldErrors.first.type, 'value_error');
    expect(error.fieldErrors.last.field, 'query.radius');
    expect(
      error.message,
      'primary_guest_email: value is not a valid email address; '
      'radius: Input should be a valid integer',
    );
  });

  test('a 422 with an empty fields list reads its message', () {
    final error = service.toApiException(
      _response(errors['validation_no_fields'], 422),
    );
    expect(error.code, 'INVALID_CURSOR');
    expect(error.message, 'Cursor does not match');
    expect(error.fieldErrors, isEmpty);
  });

  test('a domain 400 keeps its code', () {
    final error = service.toApiException(
      _response(errors['invalid_date_range'], 400),
    );
    expect(error.code, 'INVALID_DATE_RANGE');
    expect(error.message, 'The stay must cover at least one night.');
  });

  test('a 429 and a 500 envelope read as their messages', () {
    expect(
      service.toApiException(_response(errors['rate_limited'], 429)).code,
      'RATE_LIMIT_EXCEEDED',
    );
    final server = service.toApiException(_response(errors['server'], 500));
    expect(server.code, 'INTERNAL_ERROR');
    expect(server.message, 'An unexpected error occurred');
  });

  test('a body of another shape gives the status text, not the body', () {
    final html = service.toApiException(
      _response('<html>Bad gateway</html>', 502, statusMessage: 'Bad Gateway'),
    );
    expect(html.message, 'Bad Gateway');
    expect(html.code, isNull);

    // The old FastAPI shape is not read any more.
    final legacy = service.toApiException(
      _response({'detail': 'Nope'}, 400, statusMessage: 'Bad Request'),
    );
    expect(legacy.message, 'Bad Request');

    // An `error` that is text, not an envelope, is not read either.
    final text = service.toApiException(
      _response({'error': 'Nope'}, 400, statusMessage: 'Bad Request'),
    );
    expect(text.message, 'Bad Request');
  });

  test(
    'a 403 USER_INACTIVE still reaches the caller as its ApiException',
    () async {
      // The provider also ends the session. Supabase is not set up in a unit
      // test, so that step fails quietly and must not hide the error.
      final response = _response({
        'error': {
          'code': 'USER_INACTIVE',
          'message': 'This account is deactivated.',
        },
      }, 403);
      expect(
        () => UsersProvider().handleResponse(response, (_) => null),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 403)
              .having((e) => e.code, 'code', 'USER_INACTIVE'),
        ),
      );
      await pumpEventQueue();
    },
  );

  test('the 429 Retry-After header reaches the retry policy', () {
    const response = ApiResponse(
      statusCode: 429,
      headers: {'retry-after': '3'},
    );
    expect(response.retryAfter, const Duration(seconds: 3));
  });

  test('Cache-Control no-store is detected', () {
    expect(
      const ApiResponse(
        statusCode: 200,
        headers: {'cache-control': 'private, No-Store'},
      ).noStore,
      isTrue,
    );
    expect(
      const ApiResponse(
        statusCode: 200,
        headers: {'cache-control': 'max-age=60'},
      ).noStore,
      isFalse,
    );
    expect(const ApiResponse(statusCode: 200).noStore, isFalse);
  });
}
