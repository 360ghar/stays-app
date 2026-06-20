class ReviewModel {
  final String id;
  final String bookingId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
    id: map['id']?.toString() ?? '',
    bookingId:
        map['booking_id']?.toString() ?? map['bookingId']?.toString() ?? '',
    rating: (map['guest_rating'] as num? ?? map['rating'] as num? ?? 5).toInt(),
    comment:
        (map['guest_review'] as String? ?? map['comment'] as String? ?? ''),
    createdAt: (map['created_at'] == null || map['created_at'] == '')
        ? null
        : DateTime.tryParse(map['created_at'].toString()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'booking_id': bookingId,
    'rating': rating,
    'comment': comment,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}
