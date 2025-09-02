import 'base_provider.dart';

class BookingProvider extends BaseProvider {
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> payload) async {
    final response = await post('/bookings', payload);
    return handleResponse(response, (json) => json as Map<String, dynamic>);
  }
}

