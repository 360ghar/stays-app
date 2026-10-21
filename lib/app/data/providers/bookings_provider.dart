import 'base_provider.dart';
import '../../utils/exceptions/app_exceptions.dart';
import '../models/booking_model.dart';
import '../models/booking_pricing_model.dart';
import '../models/cursor_page.dart';
import '../models/message_model.dart';

/// Typed client for the bookings API.
///
/// Every success body is the resource itself and every list is a
/// `CursorPage`. Errors reach the caller as an [ApiException] that carries the
/// envelope `code`, for example `PRICING_UNAVAILABLE` or `PROPERTY_NOT_FOUND`.
class BookingsProvider extends BaseProvider {
  BookingsProvider({super.dio});

  /// Checks the guest count against the property. Stay dates are not part of
  /// the check, because overlapping bookings are allowed.
  Future<BookingOccupancy> checkOccupancy({
    required int propertyId,
    required int guests,
  }) async {
    final res = await post('/api/v1/bookings/check-availability', {
      'property_id': propertyId,
      'guests': guests,
    });
    return handleResponse(
      res,
      (json) => BookingOccupancy.fromMap(_asMap(json)),
    );
  }

  /// [checkIn] and [checkOut] are `YYYY-MM-DD`.
  Future<BookingPricingModel> calculatePricing({
    required int propertyId,
    required String checkIn,
    required String checkOut,
    required int guests,
  }) async {
    final res = await post('/api/v1/bookings/calculate-pricing', {
      'property_id': propertyId,
      'check_in_date': checkIn,
      'check_out_date': checkOut,
      'guests': guests,
    });
    return handleResponse(
      res,
      (json) => BookingPricingModel.fromMap(_asMap(json)),
    );
  }

  /// Creates a booking. A repeated [idempotencyKey] from the same caller
  /// returns the first booking, so reuse the key when the guest retries the
  /// same request by hand.
  Future<Booking> createBooking(
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) async {
    final res = await post(
      '/api/v1/bookings',
      payload,
      headers: {'Idempotency-Key': idempotencyKey},
    );
    return handleResponse(res, (json) => Booking.fromJson(_asMap(json)));
  }

  Future<CursorPage<Booking>> listBookings({
    String? cursor,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': '$limit',
    };
    final res = await get('/api/v1/bookings', query: query);
    return handleResponse(
      res,
      (json) => CursorPage.fromJson(json, Booking.fromJson),
    );
  }

  Future<Booking> getBooking(int id) async {
    final res = await get('/api/v1/bookings/$id');
    return handleResponse(res, (json) => Booking.fromJson(_asMap(json)));
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

  /// Chat of a booking, newest first. Only the guest and the host can read it.
  Future<CursorPage<MessageModel>> listMessages(
    int bookingId, {
    String? cursor,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': '$limit',
    };
    final res = await get('/api/v1/bookings/$bookingId/messages', query: query);
    return handleResponse(
      res,
      (json) => CursorPage.fromJson(json, MessageModel.fromMap),
    );
  }

  /// Sends one message. [body] is 1 to 2000 characters after trimming.
  Future<MessageModel> sendMessage(int bookingId, String body) async {
    final res = await post('/api/v1/bookings/$bookingId/messages', {
      'body': body,
    });
    return handleResponse(res, (json) => MessageModel.fromMap(_asMap(json)));
  }

  Map<String, dynamic> _asMap(dynamic json) {
    if (json is! Map) {
      throw ApiException(
        message: 'Unexpected bookings response shape',
        statusCode: 500,
      );
    }
    return Map<String, dynamic>.from(json);
  }
}
