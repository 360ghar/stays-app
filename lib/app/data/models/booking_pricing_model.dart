import 'package:json_annotation/json_annotation.dart';

part 'booking_pricing_model.g.dart';

@JsonSerializable()
class BookingPricingModel {
  @JsonKey(name: 'base_amount', fromJson: _numToDouble)
  final double baseAmount;
  @JsonKey(name: 'taxes_amount', fromJson: _numToDouble)
  final double taxesAmount;
  @JsonKey(name: 'service_charges', fromJson: _numToDouble)
  final double serviceCharges;
  @JsonKey(name: 'discount_amount', fromJson: _optionalDouble)
  final double? discountAmount;
  @JsonKey(name: 'total_amount', fromJson: _numToDouble)
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

  factory BookingPricingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingPricingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPricingModelToJson(this);

  // Backwards compatibility
  factory BookingPricingModel.fromMap(Map<String, dynamic> map) =>
      BookingPricingModel.fromJson(map);

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
}
