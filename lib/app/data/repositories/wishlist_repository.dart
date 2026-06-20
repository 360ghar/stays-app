import '../providers/swipes_provider.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';

class WishlistRepository {
  final SwipesProvider _provider;
  WishlistRepository({required SwipesProvider provider}) : _provider = provider;

  Future<void> add(int propertyId) =>
      _provider.swipe(propertyId: propertyId, isLiked: true);
  Future<void> remove(int propertyId) =>
      _provider.swipe(propertyId: propertyId, isLiked: false);

  /// Remove many liked properties in one backend call (audit UX #9).
  Future<void> clearAll(List<int> propertyIds) =>
      _provider.batchRemove(propertyIds);

  Future<UnifiedPropertyResponse> listFavorites({
    String? cursor,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    final json = await _provider.list(
      isLiked: true,
      cursor: cursor,
      limit: limit,
      filters: filters,
    );
    final rawList = json['items'] as List?;
    final properties =
        rawList?.map((e) {
          final map = Map<String, dynamic>.from(e);
          if (map['daily_rate'] == null && map['base_price'] != null) {
            final base = map['base_price'];
            if (base is num) map['daily_rate'] = base;
            if (base is String) {
              final parsed = double.tryParse(base);
              if (parsed != null) map['daily_rate'] = parsed;
            }
          }
          map['purpose'] = map['purpose'] ?? 'short_stay';
          map['currency'] = map['currency'] ?? 'INR';
          map['title'] = map['title'] ?? map['name'] ?? 'Stay';
          map['country'] = map['country'] ?? '';
          map['city'] = map['city'] ?? '';
          return Property.fromJson(map);
        }).toList() ??
        <Property>[];
    final nextCursor = json['next_cursor'] as String?;
    final hasMore = (json['has_more'] as bool?) ?? (nextCursor != null);
    final resolvedLimit = (json['limit'] as num?)?.toInt() ?? limit;
    final filtersApplied = json['filters_applied'] ?? json['filters'];
    return UnifiedPropertyResponse(
      items: properties,
      nextCursor: nextCursor,
      hasMore: hasMore,
      limit: resolvedLimit,
      filters: filtersApplied is Map
          ? Map<String, dynamic>.from(filtersApplied)
          : null,
    );
  }
}
