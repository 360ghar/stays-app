import 'app_exceptions.dart';

/// How a network request failed. Used by the retry policy to decide whether
/// retrying a request is safe (a request that was never delivered can always
/// be retried; one whose delivery is uncertain must not be retried when it
/// has side effects).
enum TransportFailureKind {
  /// No transport failure — the server returned a response (any status).
  none,

  /// The request was never delivered (connection refused, DNS failure).
  neverSent,

  /// Delivery is uncertain (timeouts, connection resets after send).
  possiblySent,
}

class NetworkExceptions extends NetworkException {
  NetworkExceptions({
    required super.message,
    super.statusCode,
    super.code,
    super.originalError,
    super.transportFailure,
  });
}
