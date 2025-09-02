import 'app_exceptions.dart';

class NetworkExceptions extends NetworkException {
  NetworkExceptions({required super.message, super.statusCode, super.code, super.originalError});
}

