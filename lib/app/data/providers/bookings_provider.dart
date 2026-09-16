import 'base_provider.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../models/booking_model.dart';
import '../models/booking_pricing_model.dart';

/// Typed client for the bookings API.
///
/// Backend envelope contract: `{data: {...}}` or `{items: [...]}` — handled
/// here so repositories and controllers never re-parse raw maps.
class BookingsProvider extends BaseProvider {
  Future<Map<String, dynamic>> checkAvailability({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) async {
    final res = await post('/api/v1/bookings/check-availability', {
      'property_id': propertyId,
      'check_in_date': checkInIso,
      'check_out_date': checkOutIso,
      'guests': guests,
    });
    return handleResponse(res, _unwrapDataMap);
  }

  Future<BookingPricingModel> calculatePricing({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) async {
    final res = await post('/api/v1/bookings/calculate-pricing', {
      'property_id': propertyId,
      'check_in_date': checkInIso,
      'check_out_date': checkOutIso,
      'guests': guests,
    });
    return handleResponse(res, (json) {
      final map = _unwrapDataMap(json);
      return BookingPricingModel.fromMap(map);
    });
  }

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    final res = await post('/api/v1/bookings', payload);
    return handleResponse(res, (json) {
      final map = _unwrapDataMap(json);
      final bookingMap = map['booking'];
      return Booking.fromJson(
        bookingMap is Map
            ? Map<String, dynamic>.from(bookingMap)
            : Map<String, dynamic>.from(map),
      );
    });
  }

  Future<List<Booking>> listBookings({String? cursor, int limit = 20}) async {
    final query = <String, dynamic>{
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': '$limit',
    };
    final res = await get('/api/v1/bookings', query: query);
    return handleResponse(res, (json) {
      final map = _unwrapDataMap(json);
      final candidates = map['items'] ?? map['data'];
      final rawList = candidates is List ? candidates : <dynamic>[];
      return rawList
          .whereType<Map>()
          .map((item) => Booking.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<Booking> getBooking(int id) async {
    final res = await get('/api/v1/bookings/$id');
    return handleResponse(res, (json) {
      final map = _unwrapDataMap(json);
      final bookingMap = map['booking'];
      return Booking.fromJson(
        bookingMap is Map
            ? Map<String, dynamic>.from(bookingMap)
            : Map<String, dynamic>.from(map),
      );
    });
  }

  Future<Booking> updateBooking(int id, Map<String, dynamic> update) async {
    final res = await put('/api/v1/bookings/$id', update);
    return handleResponse(res, (json) {
      final map = _unwrapDataMap(json);
      final bookingMap = map['booking'];
      return Booking.fromJson(
        bookingMap is Map
            ? Map<String, dynamic>.from(bookingMap)
            : Map<String, dynamic>.from(map),
      );
    });
  }

  Future<void> cancelBooking({
    required int bookingId,
    required String reason,
  }) async {
    final res = await post('/api/v1/bookings/cancel', {
      'booking_id': bookingId,
      'reason': reason,
    });
    handleResponse(res, (_) => null);
  }

  /// Unwraps the common `{data: {...}}` envelope, returning the inner map.
  Map<String, dynamic> _unwrapDataMap(dynamic json) {
    if (json is! Map) {
      throw ApiException(
        message: 'Unexpected bookings response shape',
        statusCode: 500,
      );
    }
    final map = Map<String, dynamic>.from(json);
    final data = map['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return map;
  }
}
