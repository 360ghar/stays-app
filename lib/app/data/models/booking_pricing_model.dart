class BookingPricingModel {
  final double baseAmount;
  final double taxesAmount;
  final double serviceCharges;
  final double? discountAmount;
  final double totalAmount;
  final int? nights;

  const BookingPricingModel({
    required this.baseAmount,
    required this.taxesAmount,
    required this.serviceCharges,
    required this.totalAmount,
    this.discountAmount,
    this.nights,
  });

  factory BookingPricingModel.fromMap(Map<String, dynamic> map) {
    return BookingPricingModel(
      baseAmount: _numToDouble(map['base_amount']),
      taxesAmount: _numToDouble(map['taxes_amount']),
      serviceCharges: _numToDouble(map['service_charges']),
      discountAmount: _optionalDouble(map['discount_amount']),
      totalAmount: _numToDouble(map['total_amount']),
      nights: _optionalInt(map['nights']),
    );
  }

  static double _numToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0.0;
  }

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _optionalInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
