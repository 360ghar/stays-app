import 'package:get/get.dart';
import 'debug_logger.dart';

class ErrorHandler {
  static void handleError(dynamic error, {String? context}) {
    String message = _parseError(error);
    DebugLogger.error('Error occurred: ${context ?? ''}', error);
    
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  static void handleApiError(dynamic error, {String? context}) {
    String message = _parseApiError(error);
    DebugLogger.error('API Error: ${context ?? ''}', error);
    
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
  
  static void handleNetworkError(dynamic error, {String? context}) {
    String message = 'Network error occurred. Please check your connection.';
    if (error != null && error.toString().isNotEmpty) {
      message = error.toString();
    }
    DebugLogger.error('Network Error: ${context ?? ''}', error);
    
    Get.snackbar(
      'Network Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  static String _parseError(dynamic error) {
    if (error == null) return 'An unknown error occurred';
    
    if (error is String) return error;
    
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    
    return error.toString();
  }

  static String _parseApiError(dynamic error) {
    if (error == null) return 'Network error occurred';
    
    if (error is String) return error;
    
    if (error is Map<String, dynamic>) {
      return error['message'] ?? error['error'] ?? 'API error occurred';
    }
    
    return _parseError(error);
  }

  static void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  static void showInfo(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}