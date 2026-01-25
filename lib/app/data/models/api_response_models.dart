class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool bookingUpdates;
  final bool promotions;
  final bool messages;
  final bool reminders;

  NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.bookingUpdates = true,
    this.promotions = false,
    this.messages = true,
    this.reminders = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? true,
      smsEnabled: json['smsEnabled'] ?? false,
      bookingUpdates: json['bookingUpdates'] ?? true,
      promotions: json['promotions'] ?? false,
      messages: json['messages'] ?? true,
      reminders: json['reminders'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'emailEnabled': emailEnabled,
    'smsEnabled': smsEnabled,
    'bookingUpdates': bookingUpdates,
    'promotions': promotions,
    'messages': messages,
    'reminders': reminders,
  };
}

class PrivacySettings {
  final bool profilePublic;
  final bool showEmail;
  final bool showPhone;
  final bool showListings;
  final bool showReviews;
  final bool allowMessages;

  PrivacySettings({
    this.profilePublic = true,
    this.showEmail = false,
    this.showPhone = false,
    this.showListings = true,
    this.showReviews = true,
    this.allowMessages = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profilePublic: json['profilePublic'] ?? true,
      showEmail: json['showEmail'] ?? false,
      showPhone: json['showPhone'] ?? false,
      showListings: json['showListings'] ?? true,
      showReviews: json['showReviews'] ?? true,
      allowMessages: json['allowMessages'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'profilePublic': profilePublic,
    'showEmail': showEmail,
    'showPhone': showPhone,
    'showListings': showListings,
    'showReviews': showReviews,
    'allowMessages': allowMessages,
  };
}
