import 'dart:async';
import 'dart:io';

import '../../data/providers/base_provider.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/exceptions/network_exceptions.dart';
import '../../utils/logger/app_logger.dart';

class ErrorService {
  factory ErrorService() => _shared;
  ErrorService._internal();

  // Shared instance so every provider reports into one debug history.
  static final ErrorService _shared = ErrorService._internal();

  static ErrorService get I => _shared;

  final List<String> _errorHistory = <String>[];

  /// Get the list of recent errors for debugging
  List<String> get errorHistory => _errorHistory.toList();

  /// Builds an [ApiException] from a non-2xx response.
  ///
  /// The backend sends every error as
  /// `{"error": {"code", "message", "details"}}`. A 422 lists its field errors
  /// in `details.fields` as `[{field, msg, type}]`. Nothing else is read: a
  /// body of another shape (for example a gateway page) gives the status text.
  ApiException toApiException(ApiResponse response) {
    final int statusCode = response.statusCode;
    final envelope = _readEnvelope(response.bodyAsMap());
    final fields = envelope?.fields ?? const <FieldError>[];
    final String message =
        _composeMessage(envelope?.message, fields) ??
        response.statusMessage ??
        'An unknown error occurred.';
    AppLogger.error(
      'API Error',
      'Status: $statusCode, Code: ${envelope?.code}, Message: $message',
    );
    return ApiException(
      message: message,
      statusCode: statusCode,
      code: envelope?.code,
      fieldErrors: fields,
    );
  }

  /// Get user-friendly error message from any error type
  String getErrorMessage(dynamic error) {
    if (error == null) return 'An unknown error occurred.';

    // AppException and subclasses (NetworkException, ApiException,
    // AuthException, ValidationException) carry curated, user-safe copy.
    if (error is AppException) {
      return error.message;
    }

    if (error is String) {
      return error;
    }

    // Unknown exceptions (incl. SDK internals) must never leak into
    // snackbars; log the original for diagnostics and return generic copy.
    AppLogger.debug('getErrorMessage: unexpected error type', error);
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle error with logging and context
  void handleError(dynamic error, [StackTrace? stackTrace, String? context]) {
    final String message = getErrorMessage(error);
    final String contextInfo = context != null ? '[$context] ' : '';

    AppLogger.error('${contextInfo}Error handled', error, stackTrace);

    // Add to error history (keep last 50 errors)
    _errorHistory.add(
      '${DateTime.now().toIso8601String()}: $contextInfo$message',
    );
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

    // Transport-level failures carry a classification from the retry layer.
    if (error is NetworkException &&
        error.transportFailure != null &&
        error.transportFailure != TransportFailureKind.none) {
      return 'Network error. Please check your connection and try again.';
    }
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

  _ErrorEnvelope? _readEnvelope(Map<String, dynamic> body) {
    final error = body['error'];
    if (error is! Map) return null;
    final code = error['code'];
    final message = error['message'];
    final details = error['details'];
    final rawFields = details is Map ? details['fields'] : null;
    final fields = <FieldError>[
      if (rawFields is List)
        for (final item in rawFields)
          if (item is Map && item['msg'] is String)
            FieldError(
              field: '${item['field'] ?? ''}',
              msg: item['msg'] as String,
              type: '${item['type'] ?? ''}',
            ),
    ];
    return _ErrorEnvelope(
      code: code is String ? code : null,
      message: message is String && message.trim().isNotEmpty
          ? message.trim()
          : null,
      fields: fields,
    );
  }

  /// A 422 reads as its field errors. Any other error reads as its message.
  String? _composeMessage(String? message, List<FieldError> fields) {
    if (fields.isEmpty) return message;
    return fields.map((f) => '${f.name}: ${f.msg}').join('; ');
  }
}

class _ErrorEnvelope {
  const _ErrorEnvelope({
    required this.code,
    required this.message,
    required this.fields,
  });

  final String? code;
  final String? message;
  final List<FieldError> fields;
}
