import '../models/booking_model.dart';
import '../providers/bookings_provider.dart';

class BookingRepository {
  final BookingsProvider _provider;
  BookingRepository({required BookingsProvider provider})
    : _provider = provider;

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final data = await _provider.createBooking(payload);
    return Booking.fromJson(_extractBookingPayload(data));
  }

  Future<Map<String, dynamic>> checkAvailability({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) async {
    return _provider.checkAvailability(
      propertyId: propertyId,
      checkInIso: checkInIso,
      checkOutIso: checkOutIso,
      guests: guests,
    );
  }

  Future<Map<String, dynamic>> calculatePricing({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) async {
    return _provider.calculatePricing(
      propertyId: propertyId,
      checkInIso: checkInIso,
      checkOutIso: checkOutIso,
      guests: guests,
    );
  }

  Future<List<Booking>> fetchBookings({int page = 1, int limit = 20}) async {
    final response = await _provider.listBookings(page: page, limit: limit);
    final rawList =
        (response['bookings'] as List?) ??
        (response['results'] as List?) ??
        (response['data'] as List?) ??
        <dynamic>[];
    return rawList
        .whereType<Map>()
        .map((item) => Booking.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> listBookings({int page = 1, int limit = 20}) {
    return _provider.listBookings(page: page, limit: limit);
  }

  Future<Booking> getBooking(int id) async {
    final data = await _provider.getBooking(id);
    return Booking.fromJson(_extractBookingPayload(data));
  }

  Map<String, dynamic> _extractBookingPayload(Map<String, dynamic> source) {
    if (source['booking'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(source['booking'] as Map);
    }
    return Map<String, dynamic>.from(source);
  }
}
