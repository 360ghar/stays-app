import 'app_exceptions.dart';

class TokenExpiredException extends AuthException {
  TokenExpiredException() : super(message: 'Token expired', code: 'token_expired');
}

