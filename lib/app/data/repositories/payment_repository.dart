import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class PaymentRepository {
  PaymentRepository({required PaymentProvider provider}) : _provider = provider;

  final PaymentProvider _provider;

  /// Create a Razorpay order for a booking.
  Future<RazorpayOrderModel> createRazorpayOrder(int bookingId) {
    return _provider.createRazorpayOrder(bookingId);
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
    // Prefer explicit status fields over free-form message parsing.
    if (data['success'] == true) return true;
    if (data['success'] == false) return false;
    final status = (data['status'] ?? '').toString().toLowerCase();
    if (status == 'verified' || status == 'success') return true;
    if (status == 'failed' || status == 'error') return false;
    // Last resort: substring match on message with word boundaries.
    final message = (data['message'] ?? '').toString().toLowerCase();
    return RegExp(r'\bsuccess\b|\bverified\b').hasMatch(message);
  }

  /// List the current user's saved payment methods.
  Future<List<PaymentMethodModel>> listMethods() {
    return _provider.listMethods();
  }

  /// Save a new payment method.
  Future<PaymentMethodModel> addMethod(Map<String, dynamic> payload) {
    return _provider.addMethod(payload);
  }

  /// Update a saved payment method.
  Future<PaymentMethodModel> updateMethod(
    int methodId,
    Map<String, dynamic> payload,
  ) {
    return _provider.updateMethod(methodId, payload);
  }

  /// Delete a saved payment method.
  Future<void> removeMethod(int methodId) => _provider.removeMethod(methodId);
}
