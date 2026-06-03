class ReviewModel {
  final String id;
  final String bookingId;
  final int rating;
  final String comment;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.comment,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
    id: map['id']?.toString() ?? '',
    bookingId: map['bookingId']?.toString() ?? '',
    rating: map['rating'] as int? ?? 5,
    comment: map['comment'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'bookingId': bookingId,
    'rating': rating,
    'comment': comment,
  };
}
