import 'package:get/get.dart';

import '../../data/models/booking_model.dart';
import '../../data/models/booking_pricing_model.dart';
import '../../data/repositories/booking_repository.dart';
import '../../utils/logger/app_logger.dart';
import '../../routes/app_routes.dart';

class InquiryController extends GetxController {
  final BookingRepository _repository;
  InquiryController({required BookingRepository repository})
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
      statusMessage.value = 'Inquiry created';
      await Get.offAllNamed(Routes.home, arguments: 0);
    } catch (e, stackTrace) {
      latestBooking.value = null;
      errorMessage.value = e.toString();
      statusMessage.value = 'Failed to create inquiry';
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
    required String primaryGuestEmail,
    int? nights,
    String? specialRequests,
    Map<String, dynamic>? additionalPayload,
    Map<String, num>? fallbackPricing,
  }) async {
    try {
      errorMessage.value = '';
      statusMessage.value = 'Preparing inquiry...';
      isSubmitting.value = true;

      AppLogger.info('Requesting booking pricing', {
        'property_id': propertyId,
        'check_in_date': checkInIso,
        'check_out_date': checkOutIso,
        'guests': guests,
      });

      BookingPricingModel? pricingModel;
      try {
        pricingModel = await _repository.calculatePricing(
          propertyId: propertyId,
          checkInIso: checkInIso,
          checkOutIso: checkOutIso,
          guests: guests,
        );
        if (pricingModel != null) {
          AppLogger.info('Pricing response received', {
            'base_amount': pricingModel.baseAmount,
            'taxes_amount': pricingModel.taxesAmount,
            'service_charges': pricingModel.serviceCharges,
            'discount_amount': pricingModel.discountAmount,
            'total_amount': pricingModel.totalAmount,
            'nights': pricingModel.nights,
          });
        } else {
          AppLogger.warning(
            'Pricing response was empty. Falling back to locally computed values.',
          );
        }
      } catch (error, stackTrace) {
        AppLogger.warning('Pricing request failed, using fallback values', {
          'error': error.toString(),
          'stackTrace': stackTrace.toString(),
        });
      }

      double? _sanitizeAmount(double? value) {
        if (value == null) return null;
        if (value.isNaN || value.isInfinite) return null;
        return value;
      }

      double _resolveRequiredAmount(String key, double? primary) {
        final sanitized = _sanitizeAmount(primary);
        if (sanitized != null) return sanitized;
        final fallbackValue = fallbackPricing?[key];
        if (fallbackValue != null) {
          final resolved = fallbackValue.toDouble();
          AppLogger.warning('Using fallback pricing value', {
            'key': key,
            'fallback': resolved,
          });
          return resolved;
        }
        AppLogger.warning(
          'Missing $key in pricing response. Defaulting to 0.0.',
        );
        return 0.0;
      }

      double? _resolveOptionalAmount(String key, double? primary) {
        final sanitized = _sanitizeAmount(primary);
        if (sanitized != null) return sanitized;
        final hasFallback = fallbackPricing?.containsKey(key) ?? false;
        if (hasFallback) {
          final resolved = fallbackPricing![key]!.toDouble();
          AppLogger.warning('Using fallback pricing value', {
            'key': key,
            'fallback': resolved,
          });
          return resolved;
        }
        return null;
      }

      final baseAmount = _resolveRequiredAmount(
        'base_amount',
        pricingModel?.baseAmount,
      );
      final taxesAmount = _resolveRequiredAmount(
        'taxes_amount',
        pricingModel?.taxesAmount,
      );
      final serviceCharges = _resolveRequiredAmount(
        'service_charges',
        pricingModel?.serviceCharges,
      );
      final totalAmount = _resolveRequiredAmount(
        'total_amount',
        pricingModel?.totalAmount,
      );
      final discountAmount = _resolveOptionalAmount(
        'discount_amount',
        pricingModel?.discountAmount,
      );

      AppLogger.info('Sanitized pricing values', {
        'base_amount': baseAmount,
        'taxes_amount': taxesAmount,
        'service_charges': serviceCharges,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
      });

      if (totalAmount <= 0) {
        AppLogger.warning(
          'Total amount is non-positive. Proceeding with inquiry submission.',
        );
      }

      statusMessage.value = 'Submitting inquiry...';

      int? resolvedNights = nights;
      final pricingNights = pricingModel?.nights;
      if (resolvedNights == null && pricingNights != null) {
        resolvedNights = pricingNights;
      }

      final trimmedEmail = primaryGuestEmail.trim();
      final payload = <String, dynamic>{
        'property_id': propertyId,
        'check_in_date': checkInIso,
        'check_out_date': checkOutIso,
        'guests': guests,
        'primary_guest_name': primaryGuestName,
        'primary_guest_phone': primaryGuestPhone,
        'primary_guest_email': trimmedEmail,
        // Provide a structured guest_details per API contract
        'guest_details': {'adults': guests},
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

      AppLogger.info('Submitting inquiry payload', {
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
        'has_email': trimmedEmail.isNotEmpty,
      });

      final booking = await _repository.createBooking(payload);
      latestBooking.value = booking;
      statusMessage.value = 'Inquiry created';
      AppLogger.info('Inquiry submitted successfully', {
        'booking_id': booking.id,
        'booking_status': booking.bookingStatus,
      });
    } catch (e, stackTrace) {
      latestBooking.value = null;
      errorMessage.value = e.toString();
      statusMessage.value = 'Failed to create inquiry';
      AppLogger.error('createBookingWithoutPayment failed', e, stackTrace);
    } finally {
      isSubmitting.value = false;
    }
  }
}
