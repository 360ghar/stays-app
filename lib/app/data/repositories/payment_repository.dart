import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class PaymentRepository {
  final PaymentProvider _provider;
  PaymentRepository({required PaymentProvider provider}) : _provider = provider;

  /// Legacy intent endpoint (kept for compatibility).
  Future<Map<String, dynamic>> createIntent({
    required String bookingId,
    required num amount,
  }) => _provider.createIntent(bookingId, amount);

  /// Create a Razorpay order for a booking.
  Future<RazorpayOrderModel> createRazorpayOrder(int bookingId) async {
    final data = await _provider.createRazorpayOrder(bookingId);
    return RazorpayOrderModel.fromMap(data);
  }

  /// Verify a Razorpay payment signature.
  Future<bool> verifyRazorpayPayment({
    required int bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final data = await _provider.verifyRazorpayPayment(
      bookingId: bookingId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
    final success = data['success'];
    if (success is bool) return success;
    final message = (data['message'] ?? '').toString().toLowerCase();
    return message.contains('success') || message.contains('verified');
  }

  /// List the current user's saved payment methods.
  Future<List<PaymentMethodModel>> listMethods() async {
    final list = await _provider.listMethods();
    return list.map(PaymentMethodModel.fromMap).toList();
  }

  /// Save a new payment method.
  Future<PaymentMethodModel> addMethod(Map<String, dynamic> payload) async {
    final data = await _provider.addMethod(payload);
    return PaymentMethodModel.fromMap(data);
  }

  /// Update a saved payment method.
  Future<PaymentMethodModel> updateMethod(
    int methodId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _provider.updateMethod(methodId, payload);
    return PaymentMethodModel.fromMap(data);
  }

  /// Delete a saved payment method.
  Future<void> removeMethod(int methodId) => _provider.removeMethod(methodId);
}
