import 'base_provider.dart';

class BookingsProvider extends BaseProvider {
  Future<Map<String, dynamic>> checkAvailability({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) async {
    final res = await post('/api/v1/bookings/check-availability/', {
      'property_id': propertyId,
      'check_in_date': checkInIso,
      'check_out_date': checkOutIso,
      'guests': guests,
    });
    return handleResponse(
      res,
      (json) => Map<String, dynamic>.from(json['data'] ?? json),
    );
  }

  Future<Map<String, dynamic>> calculatePricing({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) async {
    final res = await post('/api/v1/bookings/calculate-pricing/', {
      'property_id': propertyId,
      'check_in_date': checkInIso,
      'check_out_date': checkOutIso,
      'guests': guests,
    });
    return handleResponse(
      res,
      (json) => Map<String, dynamic>.from(json['data'] ?? json),
    );
  }

  Future<Map<String, dynamic>> createBooking(
    Map<String, dynamic> payload,
  ) async {
    final res = await post('/api/v1/bookings/', payload);
    return handleResponse(
      res,
      (json) => Map<String, dynamic>.from(json['data'] ?? json),
    );
  }

  Future<Map<String, dynamic>> listBookings({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await get(
      '/api/v1/bookings/',
      query: {'page': '$page', 'limit': '$limit'},
    );
    return handleResponse(
      res,
      (json) => Map<String, dynamic>.from(json['data'] ?? json),
    );
  }

  Future<Map<String, dynamic>> getBooking(int id) async {
    final res = await get('/api/v1/bookings/$id/');
    return handleResponse(
      res,
      (json) => Map<String, dynamic>.from(json['data'] ?? json),
    );
  }

  Future<Map<String, dynamic>> updateBooking(
    int id,
    Map<String, dynamic> update,
  ) async {
    final res = await put('/api/v1/bookings/$id/', update);
    return handleResponse(
      res,
      (json) => Map<String, dynamic>.from(json['data'] ?? json),
    );
  }

  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    required String reason,
  }) async {
    final res = await post('/api/v1/bookings/cancel/', {
      'booking_id': bookingId,
      'reason': reason,
    });
    return handleResponse(
      res,
      (json) => Map<String, dynamic>.from(json['data'] ?? json),
    );
  }
}
