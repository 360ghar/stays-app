import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/logger/app_logger.dart';
import '../models/booking_model.dart';
import '../models/booking_pricing_model.dart';
import '../providers/bookings_provider.dart';

class BookingRepository {
  BookingRepository({required BookingsProvider provider})
    : _provider = provider;

  final BookingsProvider _provider;

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    try {
      return await _provider.createBooking(payload);
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

  Future<Map<String, dynamic>> checkAvailability({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) {
    return _provider.checkAvailability(
      propertyId: propertyId,
      checkInIso: checkInIso,
      checkOutIso: checkOutIso,
      guests: guests,
    );
  }

  Future<BookingPricingModel?> calculatePricing({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
  }) async {
    try {
      final pricing = await _provider.calculatePricing(
        propertyId: propertyId,
        checkInIso: checkInIso,
        checkOutIso: checkOutIso,
        guests: guests,
      );
      // A parsed-but-empty pricing payload (all amounts 0.0, no nights) is
      // treated as "no pricing available" by callers via hasValidAmounts.
      return pricing;
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

  Future<List<Booking>> fetchBookings({String? cursor, int limit = 20}) {
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
}
