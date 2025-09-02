import '../providers/booking_provider.dart';

class BookingRepository {
  final BookingProvider _provider;
  BookingRepository({required BookingProvider provider}) : _provider = provider;

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> payload) async {
    return _provider.createBooking(payload);
  }
}

