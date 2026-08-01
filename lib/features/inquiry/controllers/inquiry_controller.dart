import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/booking_pricing_model.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/routes/app_routes.dart';

class InquiryController extends GetxController {
  InquiryController({required BookingRepository repository})
    : _repository = repository;

  final BookingRepository _repository;

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
            'Pricing response was empty for property $propertyId',
          );
        }
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Pricing request failed for property $propertyId',
          error,
        );
        AppLogger.error(
          'Pricing request stack trace for property $propertyId',
          error,
          stackTrace,
        );
      }

      if (pricingModel == null || !pricingModel.hasValidAmounts) {
        AppLogger.warning(
          'Pricing unavailable or invalid for property $propertyId; inquiry not submitted',
        );
        latestBooking.value = null;
        errorMessage.value = 'Pricing unavailable. Please try again.';
        statusMessage.value = 'Could not confirm pricing';
        return;
      }

      statusMessage.value = 'Submitting inquiry...';

      final payload = buildBookingPayload(
        pricing: pricingModel,
        propertyId: propertyId,
        checkInIso: checkInIso,
        checkOutIso: checkOutIso,
        guests: guests,
        primaryGuestName: primaryGuestName,
        primaryGuestPhone: primaryGuestPhone,
        primaryGuestEmail: primaryGuestEmail,
        nights: nights,
        specialRequests: specialRequests,
        additionalPayload: additionalPayload,
      );

      AppLogger.info('Submitting inquiry payload', {
        'property_id': propertyId,
        'check_in_date': checkInIso,
        'check_out_date': checkOutIso,
        'guests': guests,
        'nights': payload['nights'],
        'has_email': primaryGuestEmail.trim().isNotEmpty,
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

/// Builds the booking payload from server-authoritative [pricing].
///
/// Money fields always originate from [BookingPricingModel]; caller-supplied
/// [additionalPayload] is applied FIRST so it can never override them.
/// Throws [PricingUnavailableException] when the pricing is invalid.
@visibleForTesting
Map<String, dynamic> buildBookingPayload({
  required BookingPricingModel pricing,
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
}) {
  if (!pricing.hasValidAmounts) {
    throw const PricingUnavailableException();
  }
  final payload = <String, dynamic>{...?additionalPayload};
  payload.addAll({
    'property_id': propertyId,
    'check_in_date': checkInIso,
    'check_out_date': checkOutIso,
    'guests': guests,
    'primary_guest_name': primaryGuestName,
    'primary_guest_phone': primaryGuestPhone,
    'primary_guest_email': primaryGuestEmail,
    // Provide a structured guest_details per API contract
    'guest_details': {'adults': guests},
    'base_amount': pricing.baseAmount,
    'taxes_amount': pricing.taxesAmount,
    'service_charges': pricing.serviceCharges,
    if (pricing.discountAmount != null)
      'discount_amount': pricing.discountAmount,
    'total_amount': pricing.totalAmount,
    'booking_status': 'pending',
    'payment_status': 'pending',
  });

  final resolvedNights = nights ?? pricing.nights;
  if (resolvedNights != null) {
    payload['nights'] = resolvedNights;
  }

  if (specialRequests != null && specialRequests.trim().isNotEmpty) {
    payload['special_requests'] = specialRequests.trim();
  }

  return payload;
}
