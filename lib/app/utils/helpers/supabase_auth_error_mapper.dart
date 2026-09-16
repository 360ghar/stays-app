import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../exceptions/app_exceptions.dart';

/// Canonical product copy for Supabase Auth failures (aligned with web authErrors).
class AuthErrorMessages {
  static const invalidCredentials = 'Invalid email/phone or password.';
  static const noAccount =
      'No account found with this email or phone. Check the address or sign up.';
  static const unverified =
      'Please verify your account before signing in. We can send you a new code.';
  static const rateLimited =
      'Too many requests. Please wait a few minutes and try again.';
  static const otpInvalid = 'Invalid code. Check and try again.';
  static const otpExpired =
      'The verification code has expired. Request a new one.';
  static const smsFailed =
      "We couldn't send an SMS. Please try again or use email.";
  static const weakPassword = 'Password is too weak. Try a longer password.';
  static const sessionExpired =
      'Your session has expired. Please sign in again.';
  static const network = 'Network error. Check your connection and try again.';
  static const generic = 'Something went wrong. Please try again.';
  static const accountExists = 'An account with this email already exists.';
  static const phoneExists =
      'An account with this phone number already exists.';
}

/// Maps Supabase [supabase.AuthException] (and related errors) to [ApiException]
/// with product-facing messages and HTTP-ish status codes the controller already
/// understands (401 credentials, 429 rate limit, etc.).
///
/// Never surfaces raw `AuthException(...).toString()` dumps to the UI.
ApiException mapSupabaseAuthError(
  Object error, {
  AuthErrorContext context = AuthErrorContext.login,
}) {
  if (error is ApiException) return error;

  if (error is supabase.AuthException) {
    return _mapAuthException(error, context: context);
  }

  final raw = error.toString().toLowerCase();
  if (raw.contains('socket') ||
      raw.contains('network') ||
      raw.contains('connection') ||
      raw.contains('failed host lookup')) {
    return ApiException(
      message: AuthErrorMessages.network,
      statusCode: 0,
      code: 'network',
    );
  }

  return ApiException(
    message: AuthErrorMessages.generic,
    statusCode: 400,
    code: 'unknown',
  );
}

enum AuthErrorContext { login, otp, forgotPassword }

ApiException _mapAuthException(
  supabase.AuthException error, {
  required AuthErrorContext context,
}) {
  final code = (error.code ?? '').toLowerCase();
  final message = error.message.toLowerCase();
  final statusRaw = error.statusCode;
  final status = int.tryParse(statusRaw ?? '') ?? 400;

  switch (code) {
    case 'invalid_credentials':
    case 'invalid_grant':
      return ApiException(
        message: context == AuthErrorContext.otp
            ? AuthErrorMessages.otpInvalid
            : AuthErrorMessages.invalidCredentials,
        statusCode: 401,
        code: code,
      );
    case 'user_not_found':
      return ApiException(
        message: AuthErrorMessages.noAccount,
        statusCode: 404,
        code: code,
      );
    case 'email_exists':
    case 'user_already_exists':
      return ApiException(
        message: AuthErrorMessages.accountExists,
        statusCode: 409,
        code: code,
      );
    case 'phone_exists':
      return ApiException(
        message: AuthErrorMessages.phoneExists,
        statusCode: 409,
        code: code,
      );
    case 'email_not_confirmed':
    case 'phone_not_confirmed':
      return ApiException(
        message: AuthErrorMessages.unverified,
        statusCode: 403,
        code: code,
      );
    case 'over_email_send_rate_limit':
    case 'over_request_rate_limit':
    case 'over_sms_send_rate_limit':
    case 'too_many_requests':
      return ApiException(
        message: AuthErrorMessages.rateLimited,
        statusCode: 429,
        code: code,
      );
    case 'sms_send_failed':
      return ApiException(
        message: AuthErrorMessages.smsFailed,
        statusCode: 502,
        code: code,
      );
    case 'otp_expired':
      return ApiException(
        message: AuthErrorMessages.otpExpired,
        statusCode: 401,
        code: code,
      );
    case 'otp_disabled':
      return ApiException(
        message: AuthErrorMessages.otpInvalid,
        statusCode: 401,
        code: code,
      );
    case 'weak_password':
      return ApiException(
        message: AuthErrorMessages.weakPassword,
        statusCode: 422,
        code: code,
      );
    case 'bad_jwt':
      return ApiException(
        message: AuthErrorMessages.sessionExpired,
        statusCode: 401,
        code: code,
      );
  }

  if (_isUnverifiedMessage(message)) {
    return ApiException(
      message: AuthErrorMessages.unverified,
      statusCode: 403,
      code: 'not_confirmed',
    );
  }
  if (message.contains('invalid login') ||
      message.contains('invalid credentials') ||
      message.contains('wrong password') ||
      message.contains('password is incorrect')) {
    return ApiException(
      message: context == AuthErrorContext.otp
          ? AuthErrorMessages.otpInvalid
          : AuthErrorMessages.invalidCredentials,
      statusCode: 401,
      code: 'invalid_credentials',
    );
  }
  if (message.contains('expired') &&
      (message.contains('otp') ||
          message.contains('token') ||
          message.contains('code'))) {
    return ApiException(
      message: AuthErrorMessages.otpExpired,
      statusCode: 401,
      code: 'otp_expired',
    );
  }
  if (message.contains('rate limit') || message.contains('too many')) {
    return ApiException(
      message: AuthErrorMessages.rateLimited,
      statusCode: 429,
      code: 'rate_limit',
    );
  }
  if (message.contains('user not found') || message.contains('no user found')) {
    return ApiException(
      message: AuthErrorMessages.noAccount,
      statusCode: 404,
      code: 'user_not_found',
    );
  }
  if (message.contains('network')) {
    return ApiException(
      message: AuthErrorMessages.network,
      statusCode: 0,
      code: 'network',
    );
  }

  // Prefer Supabase's human message when short; never dump exception type names.
  final clean = error.message.trim();
  final looksLikeDump =
      clean.contains('AuthException(') ||
      clean.startsWith('Exception:') ||
      clean.length > 200;
  return ApiException(
    message: looksLikeDump || clean.isEmpty ? AuthErrorMessages.generic : clean,
    statusCode: status == 0 ? 400 : status,
    code: code.isEmpty ? 'auth_error' : code,
  );
}

bool _isUnverifiedMessage(String message) {
  return message.contains('email not confirmed') ||
      message.contains('phone not confirmed') ||
      message.contains('user not confirmed') ||
      message.contains('email address not confirmed');
}

/// Convenience for repository catch blocks: rethrow [ApiException] / map others.
Never rethrowMappedAuthError(
  Object error, {
  AuthErrorContext context = AuthErrorContext.login,
}) {
  throw mapSupabaseAuthError(error, context: context);
}
