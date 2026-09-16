import 'network_exceptions.dart' show TransportFailureKind;

class AppException implements Exception {
  AppException({required this.message, this.code, this.originalError});

  final String message;
  final String? code;
  final dynamic originalError;

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    required super.message,
    this.statusCode,
    this.transportFailure,
    super.code,
    super.originalError,
  });

  final int? statusCode;

  /// How the request failed at the transport level (null when the server
  /// responded). Set by the retry layer so callers never need to sniff
  /// exception strings.
  final TransportFailureKind? transportFailure;
}

class ApiException extends NetworkException {
  ApiException({
    required super.message,
    super.statusCode,
    super.code,
    super.transportFailure,
  });

  @override
  String toString() => statusCode != null
      ? 'ApiException($statusCode): $message'
      : 'ApiException: $message';
}

class AuthException extends AppException {
  AuthException({required super.message, super.code});
}

class ValidationException extends AppException {
  ValidationException({
    required this.errors,
    super.message = 'Validation failed',
  });

  final Map<String, List<String>> errors;
}
