import '../providers/review_provider.dart';

class ReviewRepository {
  ReviewRepository({required ReviewProvider provider}) : _provider = provider;

  final ReviewProvider _provider;

  /// Submit a review for a booking. Returns true on success.
  Future<bool> submitReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final data = await _provider.submitReview(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
    final message = (data['message'] ?? '').toString().toLowerCase();
    return message.contains('success') ||
        message.contains('added') ||
        data['success'] == true;
  }
}
