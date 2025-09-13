import 'base_provider.dart';

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
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (isLiked != null) 'is_liked': '$isLiked',
    };
    final res = await get('/api/v1/swipes/', query: query);
    return handleResponse(res, (json) => Map<String, dynamic>.from(json));
  }
}
