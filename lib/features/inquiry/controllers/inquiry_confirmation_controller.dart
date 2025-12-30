import 'dart:math' as math;

import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/routes/app_routes.dart';

class InquiryConfirmationController extends BaseController {
  InquiryConfirmationController();

  final Rxn<Property> property = Rxn<Property>();
  final Rx<DateTime> checkInDate = Rx<DateTime>(
    _normalizeDate(DateTime.now().add(const Duration(days: 7))),
  );
  final Rx<DateTime> checkOutDate = Rx<DateTime>(
    _normalizeDate(DateTime.now().add(const Duration(days: 8))),
  );
  final RxInt nights = 1.obs;
  final RxInt guests = 1.obs;

  static const int _absoluteMaxNights = 60;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Property) {
      property.value = args;
    } else if (args is Map && args['property'] is Property) {
      property.value = args['property'] as Property;
    }

    _hydrateInitialState();
    ever<Property?>(property, (_) => _hydrateInitialState());

    if (property.value == null) {
      Future.microtask(() {
        Get.snackbar(
          'Inquiry unavailable',
          'We could not load the property details. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }
  }

  void _hydrateInitialState() {
    final start = _clampCheckInDate(checkInDate.value);
    checkInDate.value = start;
    final initialNights = math.min(
      _absoluteMaxNights,
      math.max(minimumStay, nights.value),
    );
    setNights(initialNights);
    final preferredGuests = property.value?.maxGuests;
    if (preferredGuests != null && preferredGuests > 0) {
      setGuests(preferredGuests);
    } else {
      setGuests(guests.value);
    }
  }

  Future<void> submitInquiry() async {
    final selectedProperty = property.value;
    if (selectedProperty == null) {
      Get.snackbar(
        'Inquiry unavailable',
        'No property was provided for this inquiry.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final checkIn = checkInDate.value;
    final checkOut = checkOutDate.value;
    final stayLength = checkOut.difference(checkIn).inDays;
    if (stayLength <= 0) {
      setNights(minimumStay);
    }

    await Get.offNamed(
      Routes.inquiry,
      arguments: {
        'property': selectedProperty,
        'checkIn': checkInDate.value,
        'checkOut': checkOutDate.value,
        'guests': guests.value,
      },
    );
  }

  // --- Public getters ---

  int get minimumStay => math.min(
    _absoluteMaxNights,
    math.max(1, property.value?.minimumStay ?? 1),
  );

  int get maxGuests => math.max(1, property.value?.maxGuests ?? 1);

  bool get canDecrementGuests => guests.value > 1;

  bool get canIncrementGuests => guests.value < maxGuests;

  bool get canDecrementNights => nights.value > minimumStay;

  bool get canIncrementNights {
    final prospective = nights.value + 1;
    if (prospective > _absoluteMaxNights) {
      return false;
    }
    final prospectiveCheckout = checkInDate.value.add(
      Duration(days: prospective),
    );
    return !prospectiveCheckout.isAfter(maxSelectableDate);
  }

  double get nightlyRate => property.value?.pricePerNight ?? 0;

  double get baseAmount => nightlyRate * nights.value;

  double get serviceFee => baseAmount * 0.10;

  double get taxes => baseAmount * 0.05;

  double get totalAmount => baseAmount + serviceFee + taxes;

  DateTime get minSelectableDate => _normalizeDate(DateTime.now());

  DateTime get maxSelectableDate =>
      _normalizeDate(DateTime.now().add(const Duration(days: 365)));

  // --- Mutations ---

  void setCheckInDate(DateTime date) {
    final clamped = _clampCheckInDate(date);
    checkInDate.value = clamped;
    final desiredCheckout = clamped.add(Duration(days: nights.value));
    final adjustedCheckout = _clampCheckOutDate(
      checkInDate.value,
      desiredCheckout,
    );
    checkOutDate.value = adjustedCheckout;
    final actualNights = adjustedCheckout.difference(checkInDate.value).inDays;
    nights.value = math.max(minimumStay, actualNights);
  }

  void setCheckOutDate(DateTime date) {
    final adjusted = _clampCheckOutDate(checkInDate.value, date);
    final computedNights = adjusted.difference(checkInDate.value).inDays;
    checkOutDate.value = adjusted;
    final enforced = math.max(minimumStay, computedNights);
    if (enforced != nights.value) {
      setNights(enforced);
    } else {
      nights.value = enforced;
    }
  }

  void incrementNights() => setNights(nights.value + 1);

  void decrementNights() => setNights(nights.value - 1);

  void setNights(int value) {
    final sanitized = math.min(
      _absoluteMaxNights,
      math.max(minimumStay, value),
    );
    final desiredCheckout = checkInDate.value.add(Duration(days: sanitized));
    final adjustedCheckout = _clampCheckOutDate(
      checkInDate.value,
      desiredCheckout,
    );
    checkOutDate.value = adjustedCheckout;
    final actualNights = adjustedCheckout.difference(checkInDate.value).inDays;
    nights.value = math.max(minimumStay, actualNights);
  }

  void incrementGuests() => setGuests(guests.value + 1);

  void decrementGuests() => setGuests(guests.value - 1);

  void setGuests(int value) {
    if (value < 1) {
      guests.value = 1;
      return;
    }
    if (value > maxGuests) {
      guests.value = maxGuests;
      return;
    }
    guests.value = value;
  }

  // --- Helpers ---

  static DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _clampCheckInDate(DateTime date) {
    final normalized = _normalizeDate(date);
    final minDate = minSelectableDate;
    final maximumCheckIn = maxSelectableDate.subtract(
      Duration(days: minimumStay),
    );
    if (maximumCheckIn.isBefore(minDate)) {
      return minDate;
    }
    if (normalized.isBefore(minDate)) {
      return minDate;
    }
    if (normalized.isAfter(maximumCheckIn)) {
      return maximumCheckIn;
    }
    return normalized;
  }

  DateTime _clampCheckOutDate(DateTime checkIn, DateTime date) {
    final normalized = _normalizeDate(date);
    final minCheckOut = checkIn.add(const Duration(days: 1));
    final enforcedMin = checkIn.add(Duration(days: minimumStay));
    final effectiveMin = enforcedMin.isAfter(minCheckOut)
        ? enforcedMin
        : minCheckOut;
    final maxDate = maxSelectableDate;
    if (!normalized.isAfter(checkIn)) {
      return effectiveMin;
    }
    if (normalized.isBefore(effectiveMin)) {
      return effectiveMin;
    }
    if (normalized.isAfter(maxDate)) {
      return maxDate.isAfter(effectiveMin) ? maxDate : effectiveMin;
    }
    return normalized;
  }
}
