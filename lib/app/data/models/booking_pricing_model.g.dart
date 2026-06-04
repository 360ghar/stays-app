// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_pricing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingPricingModel _$BookingPricingModelFromJson(Map<String, dynamic> json) =>
    BookingPricingModel(
      baseAmount: BookingPricingModel._numToDouble(json['base_amount']),
      taxesAmount: BookingPricingModel._numToDouble(json['taxes_amount']),
      serviceCharges: BookingPricingModel._numToDouble(json['service_charges']),
      totalAmount: BookingPricingModel._numToDouble(json['total_amount']),
      discountAmount: BookingPricingModel._optionalDouble(
        json['discount_amount'],
      ),
      nights: (json['nights'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookingPricingModelToJson(
  BookingPricingModel instance,
) => <String, dynamic>{
  'base_amount': instance.baseAmount,
  'taxes_amount': instance.taxesAmount,
  'service_charges': instance.serviceCharges,
  'discount_amount': instance.discountAmount,
  'total_amount': instance.totalAmount,
  'nights': instance.nights,
};
