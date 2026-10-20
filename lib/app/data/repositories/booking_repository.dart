import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/logger/app_logger.dart';
import '../models/booking_model.dart';
import '../models/booking_pricing_model.dart';
import '../models/cursor_page.dart';
import '../models/message_model.dart';
import '../providers/bookings_provider.dart';

class BookingRepository {
  BookingRepository({required BookingsProvider provider})
    : _provider = provider;

  final BookingsProvider _provider;

  /// Creates a booking. Pass the same [idempotencyKey] again when the guest
  /// retries the same request by hand after a failure.
  Future<Booking> createBooking(
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) async {
    try {
      return await _provider.createBooking(
        payload,
        idempotencyKey: idempotencyKey,
      );
    } on ApiException catch (error, stackTrace) {
      AppLogger.error('createBooking failed', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'createBooking encountered an unexpected error',
        error,
        stackTrace,
      );
      throw ApiException(
        message: 'Unable to create booking. Please try again later.',
        statusCode: 500,
      );
    }
  }

  Future<BookingOccupancy> checkOccupancy({
    required int propertyId,
    required int guests,
  }) {
    return _provider.checkOccupancy(propertyId: propertyId, guests: guests);
  }

  /// Returns the server quote. A pricing error is an [ApiException] with the
  /// server reason (`PRICING_UNAVAILABLE`, `INVALID_DATE_RANGE`,
  /// `PROPERTY_NOT_FOUND`). [checkIn] and [checkOut] are `YYYY-MM-DD`.
  Future<BookingPricingModel> calculatePricing({
    required int propertyId,
    required String checkIn,
    required String checkOut,
    required int guests,
  }) async {
    try {
      return await _provider.calculatePricing(
        propertyId: propertyId,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
      );
    } on ApiException catch (error, stackTrace) {
      AppLogger.error('calculatePricing failed', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'calculatePricing encountered an unexpected error',
        error,
        stackTrace,
      );
      throw ApiException(
        message: 'Unable to calculate booking pricing. Please try again later.',
        statusCode: 500,
      );
    }
  }

  /// One page of the caller's bookings. Pass `next_cursor` of the last page
  /// to read the next one.
  Future<CursorPage<Booking>> fetchBookings({String? cursor, int limit = 20}) {
    return _provider.listBookings(cursor: cursor, limit: limit);
  }

  Future<Booking> getBooking(int id) async {
    try {
      return await _provider.getBooking(id);
    } on ApiException catch (error, stackTrace) {
      AppLogger.error('getBooking failed', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'getBooking encountered an unexpected error',
        error,
        stackTrace,
      );
      throw ApiException(
        message: 'Unable to load booking details. Please try again later.',
        statusCode: 500,
      );
    }
  }

  Future<void> cancelBooking({
    required int bookingId,
    String reason = 'User cancelled the inquiry',
  }) async {
    try {
      await _provider.cancelBooking(bookingId: bookingId, reason: reason);
    } on ApiException catch (error, stackTrace) {
      AppLogger.error('cancelBooking failed', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'cancelBooking encountered an unexpected error',
        error,
        stackTrace,
      );
      throw ApiException(
        message: 'Unable to cancel inquiry. Please try again later.',
        statusCode: 500,
      );
    }
  }

  /// One page of the chat of a booking, newest first.
  Future<CursorPage<MessageModel>> listMessages(
    int bookingId, {
    String? cursor,
    int limit = 50,
  }) => _provider.listMessages(bookingId, cursor: cursor, limit: limit);

  Future<MessageModel> sendMessage(int bookingId, String body) =>
      _provider.sendMessage(bookingId, body);
}
