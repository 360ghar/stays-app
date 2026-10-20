/// Server-authoritative price quote from `POST /api/v1/bookings/calculate-pricing`.
/// It is shown to the guest. It is never sent back: the booking request carries
/// no money fields, and the server prices the booking again.
class BookingPricingModel {
  const BookingPricingModel({
    required this.baseAmount,
    required this.taxesAmount,
    required this.serviceCharges,
    required this.totalAmount,
    this.discountAmount,
    this.nights,
  });

  /// Reads `BookingPricing`. Every amount is required. A missing or
  /// non-numeric amount throws a [FormatException]. It is never read as 0.
  factory BookingPricingModel.fromMap(Map<String, dynamic> map) {
    return BookingPricingModel(
      baseAmount: _requiredAmount(map, 'base_amount'),
      taxesAmount: _requiredAmount(map, 'taxes_amount'),
      serviceCharges: _requiredAmount(map, 'service_charges'),
      discountAmount: _requiredAmount(map, 'discount_amount'),
      totalAmount: _requiredAmount(map, 'total_amount'),
      nights: _optionalInt(map['nights']),
    );
  }

  final double baseAmount;
  final double taxesAmount;
  final double serviceCharges;
  final double? discountAmount;
  final double totalAmount;
  final int? nights;

  /// True when every amount is finite and non-negative and the total is
  /// positive. The inquiry form submits only with a valid quote.
  bool get hasValidAmounts {
    bool valid(double value) => !value.isNaN && !value.isInfinite && value >= 0;
    return valid(baseAmount) &&
        valid(taxesAmount) &&
        valid(serviceCharges) &&
        (discountAmount == null || valid(discountAmount!)) &&
        valid(totalAmount) &&
        totalAmount > 0;
  }

  static double _requiredAmount(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value.toDouble();
    throw FormatException('Pricing has no numeric $key.');
  }

  static int? _optionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Result of `POST /api/v1/bookings/check-availability`. The check covers the
/// guest count only. An unknown property is a 404 `PROPERTY_NOT_FOUND`.
class BookingOccupancy {
  const BookingOccupancy({
    required this.occupancyOk,
    this.reason,
    this.maxOccupancy,
  });

  factory BookingOccupancy.fromMap(Map<String, dynamic> map) {
    final ok = map['occupancy_ok'];
    if (ok is! bool) {
      throw const FormatException('The result has no occupancy_ok.');
    }
    final reason = map['reason'];
    final max = map['max_occupancy'];
    return BookingOccupancy(
      occupancyOk: ok,
      reason: reason is String ? reason : null,
      maxOccupancy: max is num ? max.toInt() : null,
    );
  }

  final bool occupancyOk;
  final String? reason;
  final int? maxOccupancy;
}
