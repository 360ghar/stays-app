import 'package:json_annotation/json_annotation.dart';

part 'amenity_model.g.dart';

@JsonSerializable()
class AmenityModel {
  const AmenityModel({required this.key, required this.name});

  factory AmenityModel.fromJson(Map<String, dynamic> json) =>
      _$AmenityModelFromJson(json);

  // Backwards compatibility
  factory AmenityModel.fromMap(Map<String, dynamic> map) =>
      AmenityModel.fromJson(map);
  final String key;
  final String name;

  Map<String, dynamic> toJson() => _$AmenityModelToJson(this);

  Map<String, dynamic> toMap() => toJson();
}
