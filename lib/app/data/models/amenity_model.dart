import 'package:json_annotation/json_annotation.dart';

part 'amenity_model.g.dart';

@JsonSerializable()
class AmenityModel {
  final String key;
  final String name;

  const AmenityModel({required this.key, required this.name});

  factory AmenityModel.fromJson(Map<String, dynamic> json) =>
      _$AmenityModelFromJson(json);

  Map<String, dynamic> toJson() => _$AmenityModelToJson(this);

  // Backwards compatibility
  factory AmenityModel.fromMap(Map<String, dynamic> map) =>
      AmenityModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
