class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isSuperHost;

  const UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.isSuperHost = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id']?.toString() ?? '',
        email: map['email'] as String? ?? '',
        firstName: map['firstName'] as String?,
        lastName: map['lastName'] as String?,
        isSuperHost: map['isSuperHost'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'isSuperHost': isSuperHost,
      };
}

