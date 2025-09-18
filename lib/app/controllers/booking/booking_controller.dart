import 'package:get/get.dart';

import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../utils/logger/app_logger.dart';

class BookingController extends GetxController {
  final BookingRepository _repository;
  BookingController({required BookingRepository repository})
    : _repository = repository;

  final RxBool isSubmitting = false.obs;
  final RxString statusMessage = ''.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Booking> latestBooking = Rxn<Booking>();

  Future<void> createBooking(Map<String, dynamic> payload) async {
    try {
      errorMessage.value = '';
      isSubmitting.value = true;
      final booking = await _repository.createBooking(payload);
      latestBooking.value = booking;
      statusMessage.value = 'Booking created';
    } catch (e, stackTrace) {
      latestBooking.value = null;
      errorMessage.value = e.toString();
      statusMessage.value = 'Failed to create booking';
      AppLogger.error('createBooking failed', e, stackTrace);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> createBookingWithoutPayment({
    required int propertyId,
    required String checkInIso,
    required String checkOutIso,
    required int guests,
    required String primaryGuestName,
    required String primaryGuestPhone,
    String? primaryGuestEmail,
    int? nights,
    String? specialRequests,
    Map<String, dynamic>? additionalPayload,
    Map<String, num>? fallbackPricing,
  }) async {
    try {
      errorMessage.value = '';
      statusMessage.value = 'Calculating price...';
      isSubmitting.value = true;

      AppLogger.info('Requesting booking pricing', {
        'property_id': propertyId,
        'check_in_date': checkInIso,
        'check_out_date': checkOutIso,
        'guests': guests,
      });

      Map<String, dynamic> pricing;
      try {
        pricing = await _repository.calculatePricing(
          propertyId: propertyId,
          checkInIso: checkInIso,
          checkOutIso: checkOutIso,
          guests: guests,
        );
        AppLogger.info('Pricing response received', pricing);
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Pricing request failed, using fallback values',
          {
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
        if (fallbackPricing != null && fallbackPricing.isNotEmpty) {
          pricing = Map<String, dynamic>.from(fallbackPricing);
        } else {
          pricing = <String, dynamic>{};
        }
      }

      double coerceAmount(String key, {bool required = true}) {
        final value = pricing[key];
        double? resolved;
        if (value is num) {
          resolved = value.toDouble();
        } else if (value is String) {
          resolved = double.tryParse(value);
        }

        final needsFallback =
            resolved == null || resolved.isNaN || resolved.isInfinite;
        if (needsFallback && fallbackPricing != null) {
          final fallbackValue = fallbackPricing[key];
          if (fallbackValue != null) {
            resolved = fallbackValue.toDouble();
            AppLogger.warning('Using fallback pricing value', {
              'key': key,
              'fallback': resolved,
            });
          }
        }

        if (resolved == null) {
          if (required) {
            AppLogger.warning(
              'Missing ' + key + ' in pricing response. Defaulting to 0.0.',
            );
          }
          return 0.0;
        }

        return resolved;
      }

      double? coerceOptionalAmount(String key) {
        final amount = coerceAmount(key, required: false);
        if (amount == 0.0 &&
            !(pricing.containsKey(key) ||
                (fallbackPricing?.containsKey(key) ?? false))) {
          return null;
        }
        return amount;
      }

      final baseAmount = coerceAmount('base_amount');
      final taxesAmount = coerceAmount('taxes_amount');
      final serviceCharges = coerceAmount('service_charges');
      final totalAmount = coerceAmount('total_amount');
      final discountAmount = coerceOptionalAmount('discount_amount');

      AppLogger.info('Sanitized pricing values', {
        'base_amount': baseAmount,
        'taxes_amount': taxesAmount,
        'service_charges': serviceCharges,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
      });

      if (totalAmount <= 0) {
        AppLogger.warning(
          'Total amount is non-positive. Proceeding with booking creation.',
        );
      }

      statusMessage.value = 'Creating booking...';

      int? resolvedNights = nights;
      final pricingNights = pricing['nights'];
      if (resolvedNights == null) {
        if (pricingNights is int) {
          resolvedNights = pricingNights;
        } else if (pricingNights is num) {
          resolvedNights = pricingNights.toInt();
        } else if (pricingNights is String) {
          resolvedNights = int.tryParse(pricingNights);
        }
      }

      final payload = <String, dynamic>{
        'property_id': propertyId,
        'check_in_date': checkInIso,
        'check_out_date': checkOutIso,
        'guests': guests,
        'primary_guest_name': primaryGuestName,
        'primary_guest_phone': primaryGuestPhone,
        if (primaryGuestEmail != null && primaryGuestEmail.trim().isNotEmpty)
          'primary_guest_email': primaryGuestEmail.trim(),
        'base_amount': baseAmount,
        'taxes_amount': taxesAmount,
        'service_charges': serviceCharges,
        if (discountAmount != null) 'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'booking_status': 'pending',
        'payment_status': 'pending',
      };

      if (resolvedNights != null) {
        payload['nights'] = resolvedNights;
      }

      if (specialRequests != null && specialRequests.trim().isNotEmpty) {
        payload['special_requests'] = specialRequests.trim();
      }

      if (additionalPayload != null && additionalPayload.isNotEmpty) {
        payload.addAll(additionalPayload);
      }

      AppLogger.info('Submitting booking payload', {
        'property_id': propertyId,
        'check_in_date': checkInIso,
        'check_out_date': checkOutIso,
        'guests': guests,
        'nights': payload['nights'],
        'base_amount': baseAmount,
        'taxes_amount': taxesAmount,
        'service_charges': serviceCharges,
        'discount_amount': payload['discount_amount'],
        'total_amount': totalAmount,
        'has_email':
            primaryGuestEmail != null && primaryGuestEmail.trim().isNotEmpty,
      });

      final booking = await _repository.createBooking(payload);
      latestBooking.value = booking;
      statusMessage.value = 'Booking created';
      AppLogger.info('Booking created successfully', {
        'booking_id': booking.id,
        'booking_status': booking.bookingStatus,
      });
    } catch (e, stackTrace) {
      latestBooking.value = null;
      errorMessage.value = e.toString();
      statusMessage.value = 'Failed to create booking';
      AppLogger.error('createBookingWithoutPayment failed', e, stackTrace);
    } finally {
      isSubmitting.value = false;
    }
  }
}
