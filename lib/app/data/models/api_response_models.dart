import 'package:json_annotation/json_annotation.dart';

part 'api_response_models.g.dart';

@JsonSerializable()
class NotificationSettings {
  @JsonKey(defaultValue: true)
  final bool pushEnabled;
  @JsonKey(defaultValue: true)
  final bool emailEnabled;
  @JsonKey(defaultValue: false)
  final bool smsEnabled;
  @JsonKey(defaultValue: true)
  final bool bookingUpdates;
  @JsonKey(defaultValue: false)
  final bool promotions;
  @JsonKey(defaultValue: true)
  final bool messages;
  @JsonKey(defaultValue: true)
  final bool reminders;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.bookingUpdates = true,
    this.promotions = false,
    this.messages = true,
    this.reminders = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);
}

@JsonSerializable()
class PrivacySettings {
  @JsonKey(defaultValue: true)
  final bool profilePublic;
  @JsonKey(defaultValue: false)
  final bool showEmail;
  @JsonKey(defaultValue: false)
  final bool showPhone;
  @JsonKey(defaultValue: true)
  final bool showListings;
  @JsonKey(defaultValue: true)
  final bool showReviews;
  @JsonKey(defaultValue: true)
  final bool allowMessages;

  const PrivacySettings({
    this.profilePublic = true,
    this.showEmail = false,
    this.showPhone = false,
    this.showListings = true,
    this.showReviews = true,
    this.allowMessages = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);
}
