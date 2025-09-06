// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wishlist_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WishlistItem _$WishlistItemFromJson(Map<String, dynamic> json) => WishlistItem(
  id: json['id'] as String,
  propertyId: _propertyIdFromJson(json['propertyId']),
  userId: json['userId'] as String?,
  action: json['action'] as String,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  property: json['property'] == null
      ? null
      : Property.fromJson(json['property'] as Map<String, dynamic>),
);

Map<String, dynamic> _$WishlistItemToJson(WishlistItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'propertyId': _propertyIdToJson(instance.propertyId),
      'userId': instance.userId,
      'action': instance.action,
      'timestamp': instance.timestamp?.toIso8601String(),
      'property': instance.property,
    };

SwipeHistory _$SwipeHistoryFromJson(Map<String, dynamic> json) => SwipeHistory(
  id: json['id'] as String,
  propertyId: _propertyIdFromJson(json['propertyId']),
  userId: json['userId'] as String?,
  action: json['action'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  property: json['property'] == null
      ? null
      : Property.fromJson(json['property'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SwipeHistoryToJson(SwipeHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'propertyId': _propertyIdToJson(instance.propertyId),
      'userId': instance.userId,
      'action': instance.action,
      'timestamp': instance.timestamp.toIso8601String(),
      'property': instance.property,
    };
