// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'property_id': instance.propertyId,
  'user_id': instance.userId,
  'booking_reference': instance.bookingReference,
  'check_in_date': instance.checkInDate.toIso8601String(),
  'check_out_date': instance.checkOutDate.toIso8601String(),
  'guests': instance.guests,
  'nights': instance.nights,
  'total_amount': instance.totalAmount,
  'booking_status': instance.bookingStatus,
  'payment_status': instance.paymentStatus,
  'created_at': instance.createdAt.toIso8601String(),
  'property_title': instance.propertyTitle,
  'property_city': instance.propertyCity,
  'property_country': instance.propertyCountry,
  'property_image_url': instance.propertyImageUrl,
  'displayTitle': instance.displayTitle,
  'displayImage': instance.displayImage,
  'displayLocation': instance.displayLocation,
};
