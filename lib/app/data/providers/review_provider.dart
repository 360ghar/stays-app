import 'base_provider.dart';

/// Model for a review
class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.propertyId,
    required this.userId,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
    this.updatedAt,
    this.hostResponse,
    this.hostResponseAt,
  });

  final String id;
  final int propertyId;
  final String userId;
  final int rating;
  final String content;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;
  final DateTime? updatedAt;
  final String? hostResponse;
  final DateTime? hostResponseAt;

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id']?.toString() ?? '',
      propertyId: _parseInt(map['property_id'] ?? map['propertyId']) ?? 0,
      userId: map['user_id']?.toString() ?? map['userId']?.toString() ?? '',
      rating: _parseInt(map['rating']) ?? 0,
      content: _asString(map['content'] ?? map['review'] ?? map['text']) ?? '',
      createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']) ??
          DateTime.now(),
      userName: _asString(map['user_name'] ?? map['userName']),
      userAvatarUrl: _asString(map['user_avatar_url'] ?? map['userAvatarUrl']),
      updatedAt: _parseDateTime(map['updated_at'] ?? map['updatedAt']),
      hostResponse: _asString(map['host_response'] ?? map['hostResponse']),
      hostResponseAt:
          _parseDateTime(map['host_response_at'] ?? map['hostResponseAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'property_id': propertyId,
        'user_id': userId,
        'rating': rating,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        if (hostResponse != null) 'host_response': hostResponse,
        if (hostResponseAt != null)
          'host_response_at': hostResponseAt!.toIso8601String(),
      };

  // Helper methods for safe type conversion
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Check if the review is valid (has content and reasonable rating)
  bool get isValid => rating >= 1 && rating <= 5 && content.isNotEmpty;

  /// Get a display-friendly rating string (e.g., "4.0")
  String get displayRating => rating.toStringAsFixed(1);
}

/// Review statistics for a property
class ReviewStats {
  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 star counts

  factory ReviewStats.fromMap(Map<String, dynamic> map) {
    final distribution = <int, int>{};
    final distData = map['rating_distribution'] ?? map['ratingDistribution'];
    if (distData is Map) {
      for (final entry in distData.entries) {
        final key = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (key != null && value is num) {
          distribution[key] = value.toInt();
        }
      }
    }

    return ReviewStats(
      averageRating:
          _parseDouble(map['average_rating'] ?? map['averageRating']) ?? 0.0,
      totalReviews:
          _parseInt(map['total_reviews'] ?? map['totalReviews']) ?? 0,
      ratingDistribution: distribution,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class ReviewProvider extends BaseProvider {
  static const String _basePath = '/api/v1/reviews';

  /// Get reviews for a specific property
  Future<List<ReviewModel>> getPropertyReviews(
    int propertyId, {
    int page = 1,
    int limit = 10,
    String? sortBy, // 'newest', 'oldest', 'highest', 'lowest'
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (sortBy != null) {
      query['sort'] = sortBy;
    }

    final res = await getWithRetry<Map<String, dynamic>>(
      '$_basePath/property/$propertyId',
      query: query,
    );

    return handleResponse(res, (data) {
      if (data == null) return <ReviewModel>[];
      final dataMap = data as Map<String, dynamic>;
      final items = (dataMap['data'] ?? dataMap['reviews'] ?? dataMap) as List?;
      if (items == null) return <ReviewModel>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromMap)
          .toList();
    });
  }

  /// Get review statistics for a property
  Future<ReviewStats> getPropertyReviewStats(int propertyId) async {
    final res = await getWithRetry<Map<String, dynamic>>(
      '$_basePath/property/$propertyId/stats',
    );

    return handleResponse(res, (data) {
      if (data == null) {
        return const ReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
        );
      }
      final dataMap = data as Map<String, dynamic>;
      final statsData = (dataMap['data'] ?? dataMap['stats'] ?? dataMap)
          as Map<String, dynamic>;
      return ReviewStats.fromMap(statsData);
    });
  }

  /// Get all reviews by the current user
  Future<List<ReviewModel>> getUserReviews({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await getWithRetry<Map<String, dynamic>>(
      '$_basePath/user',
      query: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return handleResponse(res, (data) {
      if (data == null) return <ReviewModel>[];
      final dataMap = data as Map<String, dynamic>;
      final items = (dataMap['data'] ?? dataMap['reviews'] ?? dataMap) as List?;
      if (items == null) return <ReviewModel>[];
      return items
          .whereType<Map<String, dynamic>>()
          .map(ReviewModel.fromMap)
          .toList();
    });
  }

  /// Submit a new review for a property
  Future<ReviewModel> submitReview({
    required int propertyId,
    required int rating,
    required String content,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }
    if (content.trim().isEmpty) {
      throw ArgumentError('Review content cannot be empty');
    }

    final res = await postWithRetry<Map<String, dynamic>>(
      _basePath,
      {
        'property_id': propertyId,
        'rating': rating,
        'content': content.trim(),
      },
    );

    return handleResponse(res, (data) {
      if (data == null) {
        throw Exception('Failed to submit review: empty response');
      }
      final dataMap = data as Map<String, dynamic>;
      final reviewData =
          (dataMap['data'] ?? dataMap['review'] ?? dataMap) as Map<String, dynamic>;
      return ReviewModel.fromMap(reviewData);
    });
  }

  /// Update an existing review
  Future<ReviewModel> updateReview({
    required String reviewId,
    int? rating,
    String? content,
  }) async {
    if (rating != null && (rating < 1 || rating > 5)) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (content != null) body['content'] = content.trim();

    if (body.isEmpty) {
      throw ArgumentError('At least one field (rating or content) must be provided');
    }

    final res = await put<Map<String, dynamic>>(
      '$_basePath/$reviewId',
      body,
    );

    return handleResponse(res, (data) {
      if (data == null) {
        throw Exception('Failed to update review: empty response');
      }
      final dataMap = data as Map<String, dynamic>;
      final reviewData =
          (dataMap['data'] ?? dataMap['review'] ?? dataMap) as Map<String, dynamic>;
      return ReviewModel.fromMap(reviewData);
    });
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    final res = await delete<Map<String, dynamic>>('$_basePath/$reviewId');
    handleResponse(res, (_) => null);
  }

  /// Check if the current user can review a property
  /// (usually requires a completed stay)
  Future<bool> canReviewProperty(int propertyId) async {
    final res = await getWithRetry<Map<String, dynamic>>(
      '$_basePath/can-review/$propertyId',
    );

    return handleResponse(res, (data) {
      if (data == null) return false;
      final dataMap = data as Map<String, dynamic>;
      final canReview = dataMap['can_review'] ?? dataMap['canReview'];
      if (canReview is bool) return canReview;
      return false;
    });
  }

  /// Report a review as inappropriate
  Future<void> reportReview({
    required String reviewId,
    required String reason,
  }) async {
    final res = await postWithRetry<Map<String, dynamic>>(
      '$_basePath/$reviewId/report',
      {
        'reason': reason,
      },
    );

    handleResponse(res, (_) => null);
  }

  /// Mark a review as helpful
  Future<void> markReviewHelpful(String reviewId) async {
    final res = await postWithRetry<Map<String, dynamic>>(
      '$_basePath/$reviewId/helpful',
      <String, dynamic>{},
    );

    handleResponse(res, (_) => null);
  }
}
