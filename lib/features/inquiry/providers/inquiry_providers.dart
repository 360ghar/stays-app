import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/booking_pricing_model.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

enum InquiryStatus { idle, pricing, submitting, success, error }

class InquiryFormState {
  const InquiryFormState({
    this.checkIn,
    this.checkOut,
    this.guests = 2,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.requests = '',
    this.status = InquiryStatus.idle,
    this.pricing,
    this.booking,
    this.error = '',
  });
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int guests;
  final String name;
  final String phone;
  final String email;
  final String requests;
  final InquiryStatus status;
  final BookingPricingModel? pricing;
  final Booking? booking;
  final String error;

  bool get canPrice =>
      checkIn != null &&
      checkOut != null &&
      checkOut!.isAfter(checkIn!) &&
      guests > 0;

  bool get canSubmit =>
      canPrice &&
      name.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      pricing != null &&
      pricing!.hasValidAmounts;

  int? get nights => checkIn == null || checkOut == null
      ? null
      : checkOut!.difference(checkIn!).inDays;

  InquiryFormState copyWith({
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    String? name,
    String? phone,
    String? email,
    String? requests,
    InquiryStatus? status,
    BookingPricingModel? pricing,
    bool clearPricing = false,
    Booking? booking,
    String? error,
  }) {
    return InquiryFormState(
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      requests: requests ?? this.requests,
      status: status ?? this.status,
      pricing: clearPricing ? null : (pricing ?? this.pricing),
      booking: booking ?? this.booking,
      error: error ?? this.error,
    );
  }
}

final inquiryFormProvider =
    NotifierProvider.autoDispose<InquiryFormNotifier, InquiryFormState>(
      InquiryFormNotifier.new,
    );

class InquiryFormNotifier extends AutoDisposeNotifier<InquiryFormState> {
  @override
  InquiryFormState build() => const InquiryFormState();

  BookingRepository? get _repo => Get.isRegistered<BookingRepository>()
      ? Get.find<BookingRepository>()
      : null;

  void setDates(DateTime? checkIn, DateTime? checkOut) {
    state = state.copyWith(
      checkIn: checkIn,
      checkOut: checkOut,
      clearPricing: true,
      status: InquiryStatus.idle,
      error: '',
    );
  }

  void setGuests(int guests) {
    if (guests < 1) return;
    state = state.copyWith(
      guests: guests,
      clearPricing: true,
      status: InquiryStatus.idle,
    );
  }

  void setContact({String? name, String? phone, String? email}) {
    state = state.copyWith(
      name: name ?? state.name,
      phone: phone ?? state.phone,
      email: email ?? state.email,
    );
  }

  void setRequests(String requests) {
    state = state.copyWith(requests: requests);
  }

  String _iso(DateTime day) =>
      DateTime(day.year, day.month, day.day).toIso8601String();

  Future<void> loadPricing(int propertyId) async {
    final repo = _repo;
    if (!state.canPrice || repo == null) return;
    state = state.copyWith(status: InquiryStatus.pricing, error: '');
    try {
      final pricing = await repo.calculatePricing(
        propertyId: propertyId,
        checkInIso: _iso(state.checkIn!),
        checkOutIso: _iso(state.checkOut!),
        guests: state.guests,
      );
      if (pricing == null || !pricing.hasValidAmounts) {
        state = state.copyWith(
          status: InquiryStatus.error,
          error: 'Pricing unavailable. Please try again.',
        );
        return;
      }
      state = state.copyWith(status: InquiryStatus.idle, pricing: pricing);
    } catch (e, s) {
      AppLogger.error('Inquiry v2: pricing failed', e, s);
      state = state.copyWith(
        status: InquiryStatus.error,
        error: 'Pricing unavailable. Please try again.',
      );
    }
  }

  Future<bool> submit(int propertyId) async {
    final repo = _repo;
    final pricing = state.pricing;
    if (!state.canSubmit || repo == null || pricing == null) return false;
    state = state.copyWith(status: InquiryStatus.submitting, error: '');
    try {
      final payload = buildInquiryPayload(
        pricing: pricing,
        propertyId: propertyId,
        checkInIso: _iso(state.checkIn!),
        checkOutIso: _iso(state.checkOut!),
        guests: state.guests,
        primaryGuestName: state.name.trim(),
        primaryGuestPhone: state.phone.trim(),
        primaryGuestEmail: state.email.trim(),
        nights: state.nights,
        specialRequests: state.requests,
      );
      final booking = await repo.createBooking(payload);
      state = state.copyWith(status: InquiryStatus.success, booking: booking);
      return true;
    } catch (e, s) {
      AppLogger.error('Inquiry v2: submit failed', e, s);
      state = state.copyWith(
        status: InquiryStatus.error,
        error: 'Could not submit inquiry. Please try again.',
      );
      return false;
    }
  }
}

/// Builds the booking payload from server-authoritative [pricing].
///
/// Request contract (`Map<String, dynamic>`, wire format frozen):
/// - `property_id` (int): target property.
/// - `check_in_date` / `check_out_date` (String, ISO-8601 date): stay window.
/// - `guests` (int): total guest count.
/// - `primary_guest_name` / `primary_guest_phone` / `primary_guest_email`
///   (String): contact details.
/// - `guest_details` (Map, `{adults: int}`): guest breakdown.
/// - `base_amount` / `taxes_amount` / `service_charges` / `total_amount`
///   (num, from [BookingPricingModel]): server-authoritative money fields.
/// - `discount_amount` (num?, only when non-null): applied discount.
/// - `booking_status` / `payment_status` (String): always `'pending'` here.
/// - `nights` (int?, when known): derived stay length.
/// - `special_requests` (String?, trimmed, only when non-empty).
///
/// Money fields always originate from [BookingPricingModel];
/// caller-supplied [additionalPayload] is applied FIRST so it can never
/// override them. Throws [PricingUnavailableException] when invalid.
/// Mirrors the legacy builder so both flows submit identical payloads.
Map<String, dynamic> buildInquiryPayload({
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
  // Wire format frozen: keys/types must match the backend contract above.
  payload.addAll({
    'property_id': propertyId, // int
    'check_in_date': checkInIso, // String ISO-8601
    'check_out_date': checkOutIso, // String ISO-8601
    'guests': guests, // int
    'primary_guest_name': primaryGuestName, // String
    'primary_guest_phone': primaryGuestPhone, // String
    'primary_guest_email': primaryGuestEmail, // String
    'guest_details': {'adults': guests}, // Map<String, dynamic>
    'base_amount': pricing.baseAmount, // num (server-authoritative)
    'taxes_amount': pricing.taxesAmount, // num (server-authoritative)
    'service_charges': pricing.serviceCharges, // num (server-authoritative)
    if (pricing.discountAmount != null)
      'discount_amount': pricing.discountAmount, // num? (server-authoritative)
    'total_amount': pricing.totalAmount, // num (server-authoritative)
    'booking_status': 'pending', // String
    'payment_status': 'pending', // String
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
