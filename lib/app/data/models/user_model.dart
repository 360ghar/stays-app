class UserModel {
  final String id;
  final String? email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? name;
  final bool isSuperHost;

  const UserModel({
    required this.id,
    this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.name,
    this.isSuperHost = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id']?.toString() ?? '',
        email: map['email'] as String?,
        phone: map['phone'] as String?,
        firstName: map['firstName'] as String?,
        lastName: map['lastName'] as String?,
        name: map['name'] as String?,
        isSuperHost: map['isSuperHost'] as bool? ?? false,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id']?.toString() ?? '',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        name: json['name'] as String?,
        isSuperHost: json['isSuperHost'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'name': name,
        'isSuperHost': isSuperHost,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'name': name,
        'isSuperHost': isSuperHost,
      };
}

