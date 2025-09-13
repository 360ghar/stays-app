class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? name; // Maps to API full_name when present
  final String? avatarUrl; // profile_image_url
  final Map<String, dynamic>? preferences;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool? isActive;
  final bool? isVerified;
  final DateTime? createdAt;
  final bool isSuperHost;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.name,
    this.avatarUrl,
    this.preferences,
    this.currentLatitude,
    this.currentLongitude,
    this.isActive,
    this.isVerified,
    this.createdAt,
    this.isSuperHost = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id']?.toString() ?? '',
    email: map['email'] as String?,
    phone: map['phone'] as String?,
    firstName: map['firstName'] as String?,
    lastName: map['lastName'] as String?,
    name: (map['name'] as String?) ?? (map['full_name'] as String?),
    avatarUrl:
        map['avatarUrl'] as String? ?? map['profile_image_url'] as String?,
    preferences: map['preferences'] is Map<String, dynamic>
        ? map['preferences'] as Map<String, dynamic>
        : null,
    currentLatitude: _toDouble(map['current_latitude']),
    currentLongitude: _toDouble(map['current_longitude']),
    isActive: map['is_active'] as bool?,
    isVerified: map['is_verified'] as bool?,
    createdAt: _parseDate(map['created_at']),
    isSuperHost: map['isSuperHost'] as bool? ?? false,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id']?.toString() ?? '',
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    name: (json['name'] as String?) ?? (json['full_name'] as String?),
    avatarUrl:
        json['avatarUrl'] as String? ?? json['profile_image_url'] as String?,
    preferences: json['preferences'] is Map<String, dynamic>
        ? json['preferences'] as Map<String, dynamic>
        : null,
    currentLatitude: _toDouble(json['current_latitude']),
    currentLongitude: _toDouble(json['current_longitude']),
    isActive: json['is_active'] as bool?,
    isVerified: json['is_verified'] as bool?,
    createdAt: _parseDate(json['created_at']),
    isSuperHost: json['isSuperHost'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'phone': phone,
    'firstName': firstName,
    'lastName': lastName,
    'name': name,
    'avatarUrl': avatarUrl,
    'preferences': preferences,
    'current_latitude': currentLatitude,
    'current_longitude': currentLongitude,
    'is_active': isActive,
    'is_verified': isVerified,
    'created_at': createdAt?.toIso8601String(),
    'isSuperHost': isSuperHost,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'firstName': firstName,
    'lastName': lastName,
    'name': name,
    'avatarUrl': avatarUrl,
    'preferences': preferences,
    'current_latitude': currentLatitude,
    'current_longitude': currentLongitude,
    'is_active': isActive,
    'is_verified': isVerified,
    'created_at': createdAt?.toIso8601String(),
    'isSuperHost': isSuperHost,
  };

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}
