import '../../utils/exceptions/app_exceptions.dart';
import '../../utils/logger/app_logger.dart';
import '../models/booking_model.dart';
import '../models/booking_pricing_model.dart';
import '../providers/bookings_provider.dart';

class BookingRepository {
  final BookingsProvider _provider;
  BookingRepository({required BookingsProvider provider})
    : _provider = provider;

  Future<Booking> createBooking(Map<String, dynamic> payload) async {
    try {
      final data = await _provider.createBooking(payload);
      return Booking.fromJson(_extractBookingPayload(data));
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
  }) async {
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
      final response = await _provider.calculatePricing(
        propertyId: propertyId,
        checkInIso: checkInIso,
        checkOutIso: checkOutIso,
        guests: guests,
      );
      final pricingMap = _extractPricingMap(response);
      if (pricingMap == null || pricingMap.isEmpty) {
        AppLogger.warning(
          'calculatePricing returned an empty payload',
          response,
        );
        return null;
      }
      return BookingPricingModel.fromMap(pricingMap);
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

  Map<String, dynamic>? _extractPricingMap(Map<String, dynamic> source) {
    final candidates = <dynamic>[
      source['pricing'],
      source['data'],
      source['result'],
      source['breakdown'],
    ];
    for (final candidate in candidates) {
      if (candidate is Map) {
        final mapped = candidate.map<String, dynamic>(
          (key, value) => MapEntry(key.toString(), value),
        );
        return mapped;
      }
    }
    return source.isNotEmpty ? source : null;
  }
}
