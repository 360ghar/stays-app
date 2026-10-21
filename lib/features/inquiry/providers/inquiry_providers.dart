import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/models/booking_pricing_model.dart';
import 'package:stays_app/app/data/providers/base_provider.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/helpers/json_helpers.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/providers/data_providers.dart';

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

  /// The backend requires a valid email for the primary guest.
  bool get hasEmail {
    final parts = email.trim().split('@');
    return parts.length == 2 &&
        parts[0].isNotEmpty &&
        parts[1].contains('.') &&
        !parts[1].startsWith('.') &&
        !parts[1].endsWith('.');
  }

  bool get canSubmit =>
      canPrice &&
      name.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      hasEmail &&
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

class InquiryFormNotifier extends Notifier<InquiryFormState> {
  @override
  InquiryFormState build() => const InquiryFormState();

  BookingRepository get _repo => ref.watch(bookingRepositoryProvider);

  void setDates(DateTime? checkIn, DateTime? checkOut) {
    state = state.copyWith(
      checkIn: checkIn,
      checkOut: checkOut,
      clearPricing: true,
      status: InquiryStatus.idle,
      error: '',
    );
  }

  /// [max] is the listing's guest limit when it has one.
  void setGuests(int guests, {int? max}) {
    if (guests < 1 || (max != null && guests > max)) return;
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

  /// Stay dates go on the wire as `YYYY-MM-DD`. The server reads them as
  /// midnight UTC and counts nights on those dates.
  String _day(DateTime day) => JsonHelpers.toDateOnly(day)!;

  /// The server reason when there is one (for example `PRICING_UNAVAILABLE`),
  /// else [fallback]. A retry with the same dates gets the same answer.
  String _reasonOr(Object error, String fallback) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  Future<void> loadPricing(int propertyId) async {
    if (!state.canPrice) return;
    final repo = _repo;
    state = state.copyWith(status: InquiryStatus.pricing, error: '');
    final checkIn = state.checkIn!;
    final checkOut = state.checkOut!;
    final guests = state.guests;
    // The guest may change dates or guests while the request runs. The
    // answer then belongs to an old request and is dropped.
    bool isCurrent() =>
        state.checkIn == checkIn &&
        state.checkOut == checkOut &&
        state.guests == guests;
    try {
      final pricing = await repo.calculatePricing(
        propertyId: propertyId,
        checkIn: _day(checkIn),
        checkOut: _day(checkOut),
        guests: guests,
      );
      if (!isCurrent()) return;
      if (!pricing.hasValidAmounts) {
        state = state.copyWith(
          status: InquiryStatus.error,
          error: 'Pricing unavailable. Please try again.',
        );
        return;
      }
      state = state.copyWith(status: InquiryStatus.idle, pricing: pricing);
    } catch (e, s) {
      AppLogger.error('Inquiry v2: pricing failed', e, s);
      if (!isCurrent()) return;
      state = state.copyWith(
        status: InquiryStatus.error,
        error: _reasonOr(e, 'Pricing unavailable. Please try again.'),
      );
    }
  }

  // One key per request. A guest who taps Submit again after a failure sends
  // the same request with the same key, so the server returns the first
  // booking and does not create a second one. A changed request gets a new key.
  String? _idempotencyKey;
  String? _keyedRequest;

  String _keyFor(Map<String, dynamic> payload) {
    final request = jsonEncode(payload);
    if (_idempotencyKey == null || _keyedRequest != request) {
      _idempotencyKey = generateIdempotencyKey();
      _keyedRequest = request;
    }
    return _idempotencyKey!;
  }

  Future<bool> submit(int propertyId) async {
    final repo = _repo;
    if (!state.canSubmit) return false;
    state = state.copyWith(status: InquiryStatus.submitting, error: '');
    try {
      final payload = buildInquiryPayload(
        propertyId: propertyId,
        checkIn: state.checkIn!,
        checkOut: state.checkOut!,
        guests: state.guests,
        primaryGuestName: state.name.trim(),
        primaryGuestPhone: state.phone.trim(),
        primaryGuestEmail: state.email.trim(),
        specialRequests: state.requests,
      );
      final booking = await repo.createBooking(
        payload,
        idempotencyKey: _keyFor(payload),
      );
      _idempotencyKey = null;
      _keyedRequest = null;
      state = state.copyWith(status: InquiryStatus.success, booking: booking);
      return true;
    } catch (e, s) {
      AppLogger.error('Inquiry v2: submit failed', e, s);
      state = state.copyWith(
        status: InquiryStatus.error,
        error: _reasonOr(e, 'Could not submit inquiry. Please try again.'),
      );
      return false;
    }
  }
}

/// Builds the `POST /api/v1/bookings` body.
///
/// The body carries only what the guest chose. The server prices the booking
/// and sets its status, so no money, nights or status key is sent (the body
/// rejects unknown keys).
/// - `property_id` (int)
/// - `check_in_date` / `check_out_date` (`YYYY-MM-DD`)
/// - `guests` (int)
/// - `primary_guest_name` / `primary_guest_phone` / `primary_guest_email`
/// - `guest_details` (`{adults: int}`)
/// - `special_requests` (trimmed, only when not empty)
Map<String, dynamic> buildInquiryPayload({
  required int propertyId,
  required DateTime checkIn,
  required DateTime checkOut,
  required int guests,
  required String primaryGuestName,
  required String primaryGuestPhone,
  required String primaryGuestEmail,
  String? specialRequests,
}) {
  final payload = <String, dynamic>{
    'property_id': propertyId,
    'check_in_date': JsonHelpers.toDateOnly(checkIn),
    'check_out_date': JsonHelpers.toDateOnly(checkOut),
    'guests': guests,
    'primary_guest_name': primaryGuestName,
    'primary_guest_phone': primaryGuestPhone,
    'primary_guest_email': primaryGuestEmail,
    'guest_details': {'adults': guests},
  };
  if (specialRequests != null && specialRequests.trim().isNotEmpty) {
    payload['special_requests'] = specialRequests.trim();
  }
  return payload;
}
