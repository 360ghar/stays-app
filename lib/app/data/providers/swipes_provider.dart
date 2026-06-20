import 'base_provider.dart';
import '../../utils/extensions/http_extensions.dart';

class SwipesProvider extends BaseProvider {
  Future<void> swipe({required int propertyId, required bool isLiked}) async {
    final res = await post('/api/v1/swipes/', {
      'property_id': propertyId,
      'is_liked': isLiked,
    });
    handleResponse(res, (json) => json);
  }

  Future<Map<String, dynamic>> list({
    bool? isLiked,
    String? cursor,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    final query = <String, dynamic>{
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': limit,
      if (isLiked != null) 'is_liked': isLiked,
      ...?filters,
    };
    final res = await get('/api/v1/swipes/', query: query.asQueryParams());
    return handleResponse(res, (json) => Map<String, dynamic>.from(json));
  }

  /// Remove many liked properties in a single backend call (audit UX #9).
  Future<void> batchRemove(List<int> propertyIds) async {
    if (propertyIds.isEmpty) return;
    final res = await post('/api/v1/swipes/batch-remove', {
      'property_ids': propertyIds,
    });
    handleResponse(res, (json) => json);
  }
}
