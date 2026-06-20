import 'base_provider.dart';

class PaymentProvider extends BaseProvider {
  /// Legacy intent endpoint (kept for compatibility).
  Future<Map<String, dynamic>> createIntent(
    String bookingId,
    num amount,
  ) async {
    final response = await post('/api/v1/payments/intent', {
      'bookingId': bookingId,
      'amount': amount,
    });
    return handleResponse(response, (json) => json as Map<String, dynamic>);
  }

  /// Create a Razorpay order for a booking.
  Future<Map<String, dynamic>> createRazorpayOrder(int bookingId) async {
    final response = await post('/api/v1/payments/razorpay/order', {
      'booking_id': bookingId,
    });
    return handleResponse(response, (json) {
      final map = json as Map<String, dynamic>;
      return Map<String, dynamic>.from((map['data'] as Map?) ?? map);
    });
  }

  /// Verify a Razorpay payment signature with the backend.
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required int bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await post('/api/v1/payments/razorpay/verify', {
      'booking_id': bookingId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    });
    return handleResponse(response, (json) {
      final map = json as Map<String, dynamic>;
      return Map<String, dynamic>.from((map['data'] as Map?) ?? map);
    });
  }

  /// List the current user's saved payment methods.
  Future<List<Map<String, dynamic>>> listMethods() async {
    final response = await get('/api/v1/payments/methods');
    return handleResponse(response, (json) {
      if (json is List) {
        return json
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      final map = json as Map<String, dynamic>;
      final list = map['data'] ?? map['methods'] ?? const <dynamic>[];
      if (list is! List) return <Map<String, dynamic>>[];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  /// Save a new payment method for the current user.
  Future<Map<String, dynamic>> addMethod(Map<String, dynamic> payload) async {
    final response = await post('/api/v1/payments/methods', payload);
    return handleResponse(response, (json) {
      final map = json as Map<String, dynamic>;
      return Map<String, dynamic>.from((map['data'] as Map?) ?? map);
    });
  }

  /// Update a saved payment method.
  Future<Map<String, dynamic>> updateMethod(
    int methodId,
    Map<String, dynamic> payload,
  ) async {
    final response = await put('/api/v1/payments/methods/$methodId', payload);
    return handleResponse(response, (json) {
      final map = json as Map<String, dynamic>;
      return Map<String, dynamic>.from((map['data'] as Map?) ?? map);
    });
  }

  /// Delete a saved payment method.
  Future<void> removeMethod(int methodId) async {
    final response = await delete('/api/v1/payments/methods/$methodId');
    handleResponse(response, (_) => <String, dynamic>{});
  }
}
