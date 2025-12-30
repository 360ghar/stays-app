import 'package:json_annotation/json_annotation.dart';

part 'trip_model.g.dart';

@JsonSerializable()
class TripModel {
  final String id;
  final String propertyName;
  final DateTime checkIn;
  final DateTime checkOut;
  @JsonKey(defaultValue: 'pending')
  final String status;
  final String? propertyImage;
  final double? totalCost;
  final String? hostName;

  const TripModel({
    required this.id,
    required this.propertyName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.propertyImage,
    this.totalCost,
    this.hostName,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);

  Map<String, dynamic> toJson() => _$TripModelToJson(this);

  // Backwards compatibility
  factory TripModel.fromMap(Map<String, dynamic> map) =>
      TripModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
