import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/logger/app_logger.dart';

class ErrorService extends GetxService {
  static ErrorService get I => Get.find<ErrorService>();

  final RxList<String> _errorHistory = <String>[].obs;

  /// Get the list of recent errors for debugging
  List<String> get errorHistory => _errorHistory.toList();

  ApiException toApiException(Response response) {
    final int statusCode = response.statusCode ?? 500;
    final body = response.body;
    String message = _extractMessage(body) ??
        response.bodyString ??
        response.statusText ??
        'An unknown error occurred.';
    AppLogger.error(
      'API Error',
      'Status: $statusCode, Message: $message',
    );
    return ApiException(message: message, statusCode: statusCode);
  }

  /// Get user-friendly error message from any error type
  String getErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred.';

    if (error is ApiException) {
      return error.message;
    }

    if (error is Exception) {
      final str = error.toString();
      return str.startsWith('Exception: ') ? str.substring(11) : str;
    }

    if (error is String) {
      return error;
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle error with logging and context
  void handleError(dynamic error, [StackTrace? stackTrace, String? context]) {
    final String message = getErrorMessage(error);
    final String contextInfo = context != null ? '[$context] ' : '';

    AppLogger.error('${contextInfo}Error handled', error, stackTrace);

    // Add to error history (keep last 50 errors)
    _errorHistory.add('${DateTime.now().toIso8601String()}: $contextInfo$message');
    if (_errorHistory.length > 50) {
      _errorHistory.removeAt(0);
    }
  }

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
  }

  /// Get network-related error message
  String getNetworkErrorMessage(dynamic error) {
    if (error == null) return getErrorMessage(error);

    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (error is HttpException) {
      return 'Unable to connect to server. Please try again later.';
    }
    return getErrorMessage(error);
  }

  String? _extractMessage(dynamic body) {
    if (body == null) return null;
    if (body is Map) {
      final map = body.cast<dynamic, dynamic>();
      final detail = map['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      if (detail is List) {
        final messages = <String>[];
        for (final item in detail) {
          if (item is Map) {
            final msg =
                item['msg']?.toString() ?? item['message']?.toString();
            final loc = item['loc'] is List
                ? (item['loc'] as List).map((e) => e.toString()).toList()
                : null;
            final field = loc != null && loc.isNotEmpty
                ? loc.last.toString()
                : null;
            if (msg != null && msg.isNotEmpty) {
              messages.add(field != null && field.isNotEmpty ? '$field: $msg' : msg);
            }
          } else if (item != null) {
            messages.add(item.toString());
          }
        }
        if (messages.isNotEmpty) return messages.join('; ');
      }
      if (detail is Map) {
        final msg = detail['msg']?.toString() ?? detail['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
      final msg = map['message']?.toString();
      final err = map['error']?.toString();
      final errors = map['errors'];
      if (msg != null && msg.isNotEmpty) return msg;
      if (err != null && err.isNotEmpty) return err;
      if (errors is List && errors.isNotEmpty) {
        return errors.map((e) => e.toString()).join('; ');
      }
      if (errors is Map && errors.isNotEmpty) {
        return errors.values.map((e) => e.toString()).join('; ');
      }
      return null;
    }
    return null;
  }
}

