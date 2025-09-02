class AmenityModel {
  final String key;
  final String name;

  const AmenityModel({required this.key, required this.name});

  factory AmenityModel.fromMap(Map<String, dynamic> map) =>
      AmenityModel(key: map['key'] as String, name: map['name'] as String);

  Map<String, dynamic> toMap() => {'key': key, 'name': name};
}

