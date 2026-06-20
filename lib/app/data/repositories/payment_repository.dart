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
