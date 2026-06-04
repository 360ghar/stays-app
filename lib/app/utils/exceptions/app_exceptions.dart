class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException({required this.message, this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  final int? statusCode;
  NetworkException({
    required super.message,
    this.statusCode,
    super.code,
    super.originalError,
  });
}

class ApiException extends NetworkException {
  ApiException({required super.message, super.statusCode, super.code});
}

class AuthException extends AppException {
  AuthException({required super.message, super.code});
}

class ValidationException extends AppException {
  final Map<String, List<String>> errors;
  ValidationException({
    required this.errors,
    super.message = 'Validation failed',
  });
}
