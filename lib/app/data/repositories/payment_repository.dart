import '../providers/payment_provider.dart';

class PaymentRepository {
  final PaymentProvider _provider;
  PaymentRepository({required PaymentProvider provider}) : _provider = provider;

  Future<Map<String, dynamic>> createIntent({required String bookingId, required num amount}) =>
      _provider.createIntent(bookingId, amount);
}

