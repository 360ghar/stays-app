import 'package:json_annotation/json_annotation.dart';

part 'amenity_model.g.dart';

/// An amenity as the backend sends it: `{id, title, icon, category}`.
/// `id` is the amenity id (the value `amenity_ids` takes on a write).
@JsonSerializable()
class AmenityModel {
  const AmenityModel({
    required this.id,
    required this.title,
    this.icon,
    this.category,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) =>
      _$AmenityModelFromJson(json);

  // Backwards compatibility
  factory AmenityModel.fromMap(Map<String, dynamic> map) =>
      AmenityModel.fromJson(map);
  final int id;
  final String title;
  final String? icon;
  final String? category;

  Map<String, dynamic> toJson() => _$AmenityModelToJson(this);

  Map<String, dynamic> toMap() => toJson();
}
