import 'base_provider.dart';
import '../../utils/extensions/http_extensions.dart';
import '../models/unified_property_response.dart';

class SwipesProvider extends BaseProvider {
  SwipesProvider({super.dio});

  /// `POST /api/v1/swipes`. The body is `{property_id, is_liked}` and the
  /// answer is the saved swipe (`SwipeOut`).
  Future<void> swipe({required int propertyId, required bool isLiked}) async {
    final res = await post('/api/v1/swipes', {
      'property_id': propertyId,
      'is_liked': isLiked,
    });
    handleResponse(res, (json) => json);
  }

  /// Lists swipes as a typed, cursor-paginated response. Each item is a
  /// `Property` with `liked` set. Send the same filters on every page.
  Future<UnifiedPropertyResponse> list({
    bool? isLiked,
    String? cursor,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    final query = <String, dynamic>{
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': limit,
      'is_liked': ?isLiked,
      ...?filters,
    };
    final res = await get('/api/v1/swipes', query: query.asQueryParams());
    return handleResponse(
      res,
      (json) => UnifiedPropertyResponse.fromJson(json, noStore: res.noStore),
    );
  }

  /// Removes liked properties. `BatchRemoveRequest` takes at most 100 ids, so
  /// a longer list goes out in chunks of 100.
  Future<void> batchRemove(List<int> propertyIds) async {
    for (var i = 0; i < propertyIds.length; i += _batchLimit) {
      final end = i + _batchLimit < propertyIds.length
          ? i + _batchLimit
          : propertyIds.length;
      final res = await post('/api/v1/swipes/batch-remove', {
        'property_ids': propertyIds.sublist(i, end),
      });
      handleResponse(res, (json) => json);
    }
  }

  static const _batchLimit = 100;
}
