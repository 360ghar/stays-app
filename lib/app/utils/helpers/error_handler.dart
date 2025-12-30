import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../ui/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../exceptions/app_exceptions.dart';
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
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
    );
  }

  static void _handleNetworkException(NetworkException error) {
    Get.snackbar(
      'Network Error',
      'Please check your internet connection.',
      snackPosition: SnackPosition.TOP,
    );
  }

  static void _handleAuthException(AuthException error) {
    Get.snackbar(
      'Authentication Error',
      error.message,
      snackPosition: SnackPosition.TOP,
    );
    if (error.code == 'token_expired' || error.code == 'invalid_token') {
      Get.offAllNamed(Routes.login);
    }
  }

  static void _handleValidationException(ValidationException error) {
    final firstError = error.errors.values.first.first;
    Get.snackbar(
      'Validation Error',
      firstError,
      snackPosition: SnackPosition.TOP,
    );
  }

  static void _handleGenericError(dynamic error) {
    AppLogger.error('Unhandled error', error);
    Get.snackbar(
      'Error',
      'An unexpected error occurred. Please try again.',
      snackPosition: SnackPosition.TOP,
    );
  }
}
