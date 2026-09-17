import 'base_provider.dart';
import '../../utils/extensions/http_extensions.dart';
import '../models/unified_property_response.dart';

class SwipesProvider extends BaseProvider {
  Future<void> swipe({required int propertyId, required bool isLiked}) async {
    final res = await post('/api/v1/swipes', {
      'property_id': propertyId,
      'is_liked': isLiked,
    });
    handleResponse(res, (json) => json);
  }

  /// Lists swipes as a typed, cursor-paginated response.
  ///
  /// Items are normalized here (the swipes endpoint reports `base_price`
  /// rather than `daily_rate` and may omit display defaults) so callers
  /// receive ready-to-parse `Property` models.
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
    return handleResponse(res, (json) {
      final map = Map<String, dynamic>.from(json);
      final rawItems = map['items'] as List?;
      if (rawItems != null) {
        map['items'] = rawItems.map(_normalizePropertyJson).toList();
      }
      return UnifiedPropertyResponse.fromJson(map);
    });
  }

  /// Remove many liked properties in a single backend call (audit UX #9).
  Future<void> batchRemove(List<int> propertyIds) async {
    if (propertyIds.isEmpty) return;
    final res = await post('/api/v1/swipes/batch-remove', {
      'property_ids': propertyIds,
    });
    handleResponse(res, (json) => json);
  }

  /// Shapes a raw swipe item into what [Property.fromJson] expects.
  static Map<String, dynamic> _normalizePropertyJson(dynamic item) {
    final map = Map<String, dynamic>.from(item);
    if (map['daily_rate'] == null && map['base_price'] != null) {
      final base = map['base_price'];
      if (base is num) {
        map['daily_rate'] = base;
      } else if (base is String) {
        final parsed = double.tryParse(base);
        if (parsed != null) map['daily_rate'] = parsed;
      }
    }
    map['purpose'] = map['purpose'] ?? 'short_stay';
    map['currency'] = map['currency'] ?? 'INR';
    map['title'] = map['title'] ?? map['name'] ?? 'Stay';
    map['country'] = map['country'] ?? '';
    map['city'] = map['city'] ?? '';
    return map;
  }
}
