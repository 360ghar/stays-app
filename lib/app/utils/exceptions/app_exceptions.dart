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
  NetworkException({required String message, this.statusCode, String? code, dynamic originalError})
      : super(message: message, code: code, originalError: originalError);
}

class ApiException extends NetworkException {
  ApiException({required String message, int? statusCode, String? code})
      : super(message: message, statusCode: statusCode, code: code);
}

class AuthException extends AppException {
  AuthException({required String message, String? code}) : super(message: message, code: code);
}

class ValidationException extends AppException {
  final Map<String, List<String>> errors;
  ValidationException({required this.errors, String message = 'Validation failed'})
      : super(message: message);
}

