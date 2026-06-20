import 'base_provider.dart';

class ReviewProvider extends BaseProvider {
  /// Submit a review for a booking.
  /// Maps to `POST /api/v1/bookings/review` on the backend.
  Future<Map<String, dynamic>> submitReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final response = await post('/api/v1/bookings/review', {
      'booking_id': bookingId,
      'guest_rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'guest_review': comment.trim(),
    });
    return handleResponse(response, (json) {
      final map = json as Map<String, dynamic>;
      return Map<String, dynamic>.from((map['data'] as Map?) ?? map);
    });
  }
}
