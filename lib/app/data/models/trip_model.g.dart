// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TripModel _$TripModelFromJson(Map<String, dynamic> json) => TripModel(
  id: json['id'] as String,
  propertyName: json['propertyName'] as String,
  checkIn: DateTime.parse(json['checkIn'] as String),
  checkOut: DateTime.parse(json['checkOut'] as String),
  status: json['status'] as String? ?? 'pending',
  propertyImage: json['propertyImage'] as String?,
  totalCost: (json['totalCost'] as num?)?.toDouble(),
  hostName: json['hostName'] as String?,
);

Map<String, dynamic> _$TripModelToJson(TripModel instance) => <String, dynamic>{
  'id': instance.id,
  'propertyName': instance.propertyName,
  'checkIn': instance.checkIn.toIso8601String(),
  'checkOut': instance.checkOut.toIso8601String(),
  'status': instance.status,
  'propertyImage': instance.propertyImage,
  'totalCost': instance.totalCost,
  'hostName': instance.hostName,
};
