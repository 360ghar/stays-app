import 'base_provider.dart';

class PaymentProvider extends BaseProvider {
  Future<Map<String, dynamic>> createIntent(String bookingId, num amount) async {
    final response = await post('/payments/intent', {'bookingId': bookingId, 'amount': amount});
    return handleResponse(response, (json) => json as Map<String, dynamic>);
  }
}

