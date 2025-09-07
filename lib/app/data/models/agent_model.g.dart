// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentModel _$AgentModelFromJson(Map<String, dynamic> json) => AgentModel(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  profileImage: json['profileImage'] as String?,
  bio: json['bio'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  totalListings: (json['totalListings'] as num?)?.toInt(),
  totalReviews: (json['totalReviews'] as num?)?.toInt(),
  memberSince: json['memberSince'] == null
      ? null
      : DateTime.parse(json['memberSince'] as String),
  isVerified: json['isVerified'] as bool?,
  agency: json['agency'] as String?,
  licenseNumber: json['licenseNumber'] as String?,
  languages: (json['languages'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$AgentModelToJson(AgentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'profileImage': instance.profileImage,
      'bio': instance.bio,
      'rating': instance.rating,
      'totalListings': instance.totalListings,
      'totalReviews': instance.totalReviews,
      'memberSince': instance.memberSince?.toIso8601String(),
      'isVerified': instance.isVerified,
      'agency': instance.agency,
      'licenseNumber': instance.licenseNumber,
      'languages': instance.languages,
      'metadata': instance.metadata,
    };
