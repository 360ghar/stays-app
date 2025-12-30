import 'package:json_annotation/json_annotation.dart';

part 'review_model.g.dart';

@JsonSerializable()
class ReviewModel {
  final String id;
  final String bookingId;
  @JsonKey(defaultValue: 5)
  final int rating;
  @JsonKey(defaultValue: '')
  final String comment;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewModelToJson(this);

  // Backwards compatibility
  factory ReviewModel.fromMap(Map<String, dynamic> map) =>
      ReviewModel.fromJson(map);

  Map<String, dynamic> toMap() => toJson();
}
