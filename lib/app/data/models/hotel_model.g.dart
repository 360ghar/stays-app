// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hotel_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Hotel _$HotelFromJson(Map<String, dynamic> json) => Hotel(
  id: json['id'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String,
  city: json['city'] as String,
  country: json['country'] as String,
  rating: (json['rating'] as num).toDouble(),
  reviews: (json['reviews'] as num).toInt(),
  pricePerNight: (json['pricePerNight'] as num).toDouble(),
  currency: json['currency'] as String? ?? AppConstants.defaultCurrencySymbol,
  propertyType: json['propertyType'] as String? ?? 'Hotel',
  isFavorite: json['isFavorite'] as bool? ?? false,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  amenities: (json['amenities'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  description: json['description'] as String?,
);

Map<String, dynamic> _$HotelToJson(Hotel instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'imageUrl': instance.imageUrl,
  'city': instance.city,
  'country': instance.country,
  'rating': instance.rating,
  'reviews': instance.reviews,
  'pricePerNight': instance.pricePerNight,
  'currency': instance.currency,
  'propertyType': instance.propertyType,
  'isFavorite': instance.isFavorite,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'amenities': instance.amenities,
  'description': instance.description,
};
