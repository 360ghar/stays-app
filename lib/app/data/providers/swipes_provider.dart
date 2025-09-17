import 'base_provider.dart';

class SwipesProvider extends BaseProvider {
  Map<String, String> _stringify(Map<String, dynamic> map) {
    final out = <String, String>{};
    map.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        if (value.isNotEmpty) out[key] = value.join(',');
      } else {
        out[key] = value.toString();
      }
    });
    return out;
  }

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
    Map<String, dynamic>? filters,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (isLiked != null) 'is_liked': isLiked,
      ...?filters,
    };
    final res = await get('/api/v1/swipes/', query: _stringify(query));
    return handleResponse(res, (json) => Map<String, dynamic>.from(json));
  }
}
