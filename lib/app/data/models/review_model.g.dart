// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewModel _$ReviewModelFromJson(Map<String, dynamic> json) => ReviewModel(
  id: json['id'] as String,
  bookingId: json['bookingId'] as String,
  rating: (json['rating'] as num?)?.toInt() ?? 5,
  comment: json['comment'] as String? ?? '',
);

Map<String, dynamic> _$ReviewModelToJson(ReviewModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'rating': instance.rating,
      'comment': instance.comment,
    };
