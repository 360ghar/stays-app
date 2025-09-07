// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VisitModel _$VisitModelFromJson(Map<String, dynamic> json) => VisitModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  propertyId: json['propertyId'] as String,
  visitDate: DateTime.parse(json['visitDate'] as String),
  status: json['status'] as String,
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$VisitModelToJson(VisitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'propertyId': instance.propertyId,
      'visitDate': instance.visitDate.toIso8601String(),
      'status': instance.status,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
