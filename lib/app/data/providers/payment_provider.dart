import 'base_provider.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../models/payment_model.dart';

/// Typed client for the payments API.
///
/// Backend envelope contract: `{data: {...}}` / `{data: [...]}` — unwrapped
/// here so repositories and controllers never re-parse raw maps.
class PaymentProvider extends BaseProvider {
  /// Create a Razorpay order for a booking.
  Future<RazorpayOrderModel> createRazorpayOrder(int bookingId) async {
    final response = await post('/api/v1/payments/razorpay/order', {
      'booking_id': bookingId,
    });
    return handleResponse(response, (json) {
      return RazorpayOrderModel.fromMap(_unwrapDataMap(json));
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
    return handleResponse(response, _unwrapDataMap);
  }

  /// List the current user's saved payment methods.
  Future<List<PaymentMethodModel>> listMethods() async {
    final response = await get('/api/v1/payments/methods');
    return handleResponse(response, (json) {
      if (json is List) {
        return json
            .whereType<Map>()
            .map(
              (e) => PaymentMethodModel.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
      final map = _unwrapDataMap(json);
      final list = map['data'] ?? map['methods'] ?? const <dynamic>[];
      if (list is! List) return <PaymentMethodModel>[];
      return list
          .whereType<Map>()
          .map((e) => PaymentMethodModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    });
  }

  /// Save a new payment method for the current user.
  Future<PaymentMethodModel> addMethod(Map<String, dynamic> payload) async {
    final response = await post('/api/v1/payments/methods', payload);
    return handleResponse(response, (json) {
      return PaymentMethodModel.fromMap(_unwrapDataMap(json));
    });
  }

  /// Update a saved payment method.
  Future<PaymentMethodModel> updateMethod(
    int methodId,
    Map<String, dynamic> payload,
  ) async {
    final response = await put('/api/v1/payments/methods/$methodId', payload);
    return handleResponse(response, (json) {
      return PaymentMethodModel.fromMap(_unwrapDataMap(json));
    });
  }

  /// Delete a saved payment method.
  Future<void> removeMethod(int methodId) async {
    final response = await delete('/api/v1/payments/methods/$methodId');
    handleResponse(response, (_) => null);
  }

  /// Unwraps the common `{data: {...}}` envelope, returning the inner map.
  Map<String, dynamic> _unwrapDataMap(dynamic json) {
    if (json is! Map) {
      throw ApiException(
        message: 'Unexpected payments response shape',
        statusCode: 500,
      );
    }
    final map = Map<String, dynamic>.from(json);
    final data = map['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return map;
  }
}
