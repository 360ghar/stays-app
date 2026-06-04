// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'supabase_id': instance.supabaseId,
  'email': instance.email,
  'phone': instance.phone,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'name': instance.name,
  'avatarUrl': instance.avatarUrl,
  'profile_image_url': instance.profileImageUrl,
  'bio': instance.bio,
  'date_of_birth': instance.dateOfBirth?.toIso8601String(),
  'preferences': instance.preferences,
  'notification_settings': instance.notificationSettings,
  'privacy_settings': instance.privacySettings,
  'current_latitude': instance.currentLatitude,
  'current_longitude': instance.currentLongitude,
  'is_active': instance.isActive,
  'is_verified': instance.isVerified,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'isSuperHost': instance.isSuperHost,
  'agent_id': instance.agentId,
  'metadata': instance.metadata,
  'fullName': instance.fullName,
  'displayName': instance.displayName,
  'initials': instance.initials,
  'effectiveAvatarUrl': instance.effectiveAvatarUrl,
  'hasProfileImage': instance.hasProfileImage,
};
