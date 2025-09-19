class UserModel {
  final String id;
  final String? supabaseId;
  final String? email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? avatarUrl;
  final String? profileImageUrl;
  final String? bio;
  final DateTime? dateOfBirth;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? notificationSettings;
  final Map<String, dynamic>? privacySettings;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool? isActive;
  final bool? isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSuperHost;
  final String? agentId;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    this.supabaseId,
    this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.name,
    this.avatarUrl,
    this.profileImageUrl,
    this.bio,
    this.dateOfBirth,
    this.preferences,
    this.notificationSettings,
    this.privacySettings,
    this.currentLatitude,
    this.currentLongitude,
    this.isActive,
    this.isVerified,
    this.createdAt,
    this.updatedAt,
    this.isSuperHost = false,
    this.agentId,
    this.metadata,
  });

  String get fullName {
    final buffer = StringBuffer();
    if ((firstName ?? '').trim().isNotEmpty) {
      buffer.write(firstName!.trim());
    }
    if ((lastName ?? '').trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(lastName!.trim());
    }
    if (buffer.isNotEmpty) {
      return buffer.toString();
    }
    if ((name ?? '').trim().isNotEmpty) {
      return name!.trim();
    }
    return '';
  }

  String get displayName {
    final fallback = email ?? phone ?? 'Guest';
    final computed = fullName;
    if (computed.isNotEmpty) return computed;
    if ((name ?? '').trim().isNotEmpty) return name!.trim();
    return fallback;
  }

  String get initials {
    final source = fullName.isNotEmpty ? fullName : displayName;
    final cleaned = source.trim();
    if (cleaned.isEmpty) return 'GU';
    final parts = cleaned.split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final second = parts.length > 1 ? parts[1] : '';
    final buffer = StringBuffer();
    if (first.isNotEmpty) buffer.write(first[0].toUpperCase());
    if (second.isNotEmpty) {
      buffer.write(second[0].toUpperCase());
    } else if (parts.length == 1 && parts.first.length > 1) {
      buffer.write(parts.first[1].toUpperCase());
    }
    return buffer.isEmpty
        ? cleaned.substring(0, 1).toUpperCase()
        : buffer.toString();
  }

  String? get effectiveAvatarUrl => profileImageUrl ?? avatarUrl;

  bool get hasProfileImage => (effectiveAvatarUrl ?? '').isNotEmpty;

  UserModel copyWith({
    String? id,
    String? supabaseId,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? name,
    String? avatarUrl,
    String? profileImageUrl,
    String? bio,
    DateTime? dateOfBirth,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? notificationSettings,
    Map<String, dynamic>? privacySettings,
    double? currentLatitude,
    double? currentLongitude,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSuperHost,
    String? agentId,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      supabaseId: supabaseId ?? this.supabaseId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      preferences: preferences ?? this.preferences,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSuperHost: isSuperHost ?? this.isSuperHost,
      agentId: agentId ?? this.agentId,
      metadata: metadata ?? this.metadata,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parseMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((key, dynamic v) => MapEntry('$key', v));
      }
      return null;
    }

    return UserModel(
      id: _asString(map['id']) ?? '',
      supabaseId: _asString(map['supabase_id']) ?? _asString(map['supabaseId']),
      email: _asString(map['email']),
      phone: _asString(map['phone']),
      firstName: _asString(map['firstName']) ?? _asString(map['first_name']),
      lastName: _asString(map['lastName']) ?? _asString(map['last_name']),
      name: _asString(map['name']) ?? _asString(map['full_name']),
      avatarUrl:
          _asString(map['avatarUrl']) ??
          _asString(map['avatar_url']) ??
          _asString(map['profile_image_url']),
      profileImageUrl:
          _asString(map['profileImageUrl']) ??
          _asString(map['profile_image_url']) ??
          _asString(map['avatarUrl']),
      bio: _asString(map['bio']),
      dateOfBirth: _parseDate(
        map['date_of_birth'] ?? map['dob'] ?? map['dateOfBirth'],
      ),
      preferences: parseMap(map['preferences']),
      notificationSettings: parseMap(
        map['notification_settings'] ?? map['notificationSettings'],
      ),
      privacySettings: parseMap(
        map['privacy_settings'] ?? map['privacySettings'],
      ),
      currentLatitude: _toDouble(
        map['current_latitude'] ?? map['currentLatitude'],
      ),
      currentLongitude: _toDouble(
        map['current_longitude'] ?? map['currentLongitude'],
      ),
      isActive: map['is_active'] as bool? ?? map['isActive'] as bool?,
      isVerified: map['is_verified'] as bool? ?? map['isVerified'] as bool?,
      createdAt: _parseDate(map['created_at'] ?? map['createdAt']),
      updatedAt: _parseDate(map['updated_at'] ?? map['updatedAt']),
      isSuperHost:
          map['isSuperHost'] as bool? ?? map['is_super_host'] as bool? ?? false,
      agentId: _asString(map['agent_id']) ?? _asString(map['agentId']),
      metadata: parseMap(map['metadata']),
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      UserModel.fromMap(json);

  Map<String, dynamic> toMap() => {
    'id': id,
    'supabase_id': supabaseId,
    'email': email,
    'phone': phone,
    'firstName': firstName,
    'lastName': lastName,
    'name': name,
    'avatarUrl': avatarUrl,
    'profileImageUrl': profileImageUrl ?? avatarUrl,
    'profile_image_url': profileImageUrl ?? avatarUrl,
    'bio': bio,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'preferences': preferences,
    'notification_settings': notificationSettings,
    'privacy_settings': privacySettings,
    'current_latitude': currentLatitude,
    'current_longitude': currentLongitude,
    'is_active': isActive,
    'is_verified': isVerified,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'isSuperHost': isSuperHost,
    'agent_id': agentId,
    'metadata': metadata,
  };

  Map<String, dynamic> toJson() => toMap();

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}
