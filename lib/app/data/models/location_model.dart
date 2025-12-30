import 'package:json_annotation/json_annotation.dart';

part 'location_model.g.dart';

@JsonSerializable()
class LocationModel {
  final String city;
  final String country;
  @JsonKey(defaultValue: 0.0)
  final double lat;
  @JsonKey(defaultValue: 0.0)
  final double lng;

  const LocationModel({
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) =>
      _$LocationModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationModelToJson(this);

  // Backwards compatibility
  factory LocationModel.fromMap(Map<String, dynamic> map) =>
      LocationModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
