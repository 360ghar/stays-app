import '../providers/bookings_provider.dart';

class BookingRepository {
  final BookingsProvider _provider;
  BookingRepository({required BookingsProvider provider})
    : _provider = provider;

  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> payload,
  ) async {
    return _provider.createBooking(payload);
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

  Future<Map<String, dynamic>> listBookings({int page = 1, int limit = 20}) {
    return _provider.listBookings(page: page, limit: limit);
  }

  Future<Map<String, dynamic>> getBooking(int id) {
    return _provider.getBooking(id);
  }
}
