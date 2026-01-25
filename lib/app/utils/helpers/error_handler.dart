import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../exceptions/app_exceptions.dart';
import '../helpers/app_snackbar.dart';
import '../logger/app_logger.dart';

class ErrorHandler {
  static void handleError(dynamic error) {
    if (error is ApiException) {
      _handleApiException(error);
    } else if (error is AuthException) {
      _handleAuthException(error);
    } else if (error is NetworkException) {
      _handleNetworkException(error);
    } else if (error is ValidationException) {
      _handleValidationException(error);
    } else {
      _handleGenericError(error);
    }
  }

  static void _handleApiException(ApiException error) {
    String message = error.message;
    switch (error.statusCode) {
      case 401:
        message = 'Session expired. Please login again.';
        Get.offAllNamed(Routes.login);
        break;
      case 403:
        message = 'You don\'t have permission to perform this action.';
        break;
      case 404:
        message = 'The requested resource was not found.';
        break;
      case 500:
        message = 'Server error. Please try again later.';
        break;
    }
    AppSnackbar.error(title: 'Error', message: message);
  }

  static void _handleNetworkException(NetworkException error) {
    AppSnackbar.error(
      title: 'Network Error',
      message: 'Please check your internet connection.',
    );
  }

  static void _handleAuthException(AuthException error) {
    AppSnackbar.error(title: 'Authentication Error', message: error.message);
    if (error.code == 'token_expired' || error.code == 'invalid_token') {
      Get.offAllNamed(Routes.login);
    }
  }

  static void _handleValidationException(ValidationException error) {
    final firstError = error.errors.values.first.first;
    AppSnackbar.warning(title: 'Validation Error', message: firstError);
  }

  static void _handleGenericError(dynamic error) {
    AppLogger.error('Unhandled error', error);
    AppSnackbar.error(
      title: 'Error',
      message: 'An unexpected error occurred. Please try again.',
    );
  }
}
