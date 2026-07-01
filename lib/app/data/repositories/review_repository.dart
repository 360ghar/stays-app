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
    // Prefer explicit status fields over free-form message parsing.
    if (data['success'] == true) return true;
    if (data['success'] == false) return false;
    final status = (data['status'] ?? '').toString().toLowerCase();
    if (status == 'success' || status == 'added') return true;
    if (status == 'failed' || status == 'error') return false;
    // Last resort: substring match on message with word boundaries.
    final message = (data['message'] ?? '').toString().toLowerCase();
    return RegExp(r'\bsuccess\b|\badded\b').hasMatch(message);
  }
}
