import 'network_exceptions.dart' show TransportFailureKind;

class AppException implements Exception {
  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.component,
    this.operation,
    this.statusCode,
  });

  final String message;
  final String? code;
  final dynamic originalError;

  /// Component that raised the error (e.g. 'auth', 'listing', 'booking').
  /// Optional and null by default so every existing constructor call keeps
  /// compiling unchanged.
  final String? component;

  /// Operation in progress when the error occurred (e.g. 'login',
  /// 'refreshSession', 'fetchListings'). Same null-default contract.
  final String? operation;

  /// HTTP status when the error maps to one (null for local failures).
  /// Lives on the base so loggers/reporters read it without downcasting;
  /// subclasses forward it via super parameters.
  final int? statusCode;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.statusCode,
    this.transportFailure,
    super.code,
    super.originalError,
    super.component,
    super.operation,
  });

  /// How the request failed at the transport level (null when the server
  /// responded). Set by the retry layer so callers never need to sniff
  /// exception strings.
  final TransportFailureKind? transportFailure;
}

/// One entry of `error.details.fields` on a 422: `{field, msg, type}`.
/// `field` keeps its source prefix, for example `body.primary_guest_email`.
class FieldError {
  const FieldError({
    required this.field,
    required this.msg,
    required this.type,
  });

  final String field;
  final String msg;
  final String type;

  /// The field name without its `body.`, `query.` or `path.` prefix.
  String get name {
    final dot = field.indexOf('.');
    return dot == -1 ? field : field.substring(dot + 1);
  }
}

class ApiException extends NetworkException {
  ApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.transportFailure,
    super.component,
    super.operation,
    this.fieldErrors = const <FieldError>[],
  });

  /// Field errors of a 422 (`details.fields`). Empty for every other status.
  final List<FieldError> fieldErrors;

  @override
  String toString() => statusCode != null
      ? 'ApiException($statusCode): $message'
      : 'ApiException: $message';
}

class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code,
    super.component,
    super.operation,
    super.statusCode,
  });
}

class ValidationException extends AppException {
  ValidationException({
    required this.errors,
    super.message = 'Validation failed',
    super.component,
    super.operation,
    super.statusCode,
  });

  final Map<String, List<String>> errors;
}
