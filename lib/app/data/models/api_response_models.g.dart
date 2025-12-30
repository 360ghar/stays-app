// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettings _$NotificationSettingsFromJson(
  Map<String, dynamic> json,
) => NotificationSettings(
  pushEnabled: json['pushEnabled'] as bool? ?? true,
  emailEnabled: json['emailEnabled'] as bool? ?? true,
  smsEnabled: json['smsEnabled'] as bool? ?? false,
  bookingUpdates: json['bookingUpdates'] as bool? ?? true,
  promotions: json['promotions'] as bool? ?? false,
  messages: json['messages'] as bool? ?? true,
  reminders: json['reminders'] as bool? ?? true,
);

Map<String, dynamic> _$NotificationSettingsToJson(
  NotificationSettings instance,
) => <String, dynamic>{
  'pushEnabled': instance.pushEnabled,
  'emailEnabled': instance.emailEnabled,
  'smsEnabled': instance.smsEnabled,
  'bookingUpdates': instance.bookingUpdates,
  'promotions': instance.promotions,
  'messages': instance.messages,
  'reminders': instance.reminders,
};

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      profilePublic: json['profilePublic'] as bool? ?? true,
      showEmail: json['showEmail'] as bool? ?? false,
      showPhone: json['showPhone'] as bool? ?? false,
      showListings: json['showListings'] as bool? ?? true,
      showReviews: json['showReviews'] as bool? ?? true,
      allowMessages: json['allowMessages'] as bool? ?? true,
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'profilePublic': instance.profilePublic,
      'showEmail': instance.showEmail,
      'showPhone': instance.showPhone,
      'showListings': instance.showListings,
      'showReviews': instance.showReviews,
      'allowMessages': instance.allowMessages,
    };
