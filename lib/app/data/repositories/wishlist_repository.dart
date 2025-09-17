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

  Future<UnifiedPropertyResponse> listFavorites({
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    final json = await _provider.list(
      isLiked: true,
      page: page,
      limit: limit,
      filters: filters,
    );
    final rawList = (json['properties'] as List?) ??
        (json['data'] is Map<String, dynamic>
            ? (json['data'] as Map<String, dynamic>)['properties'] as List?
            : null);
    final properties = rawList
            ?.map((e) {
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
            })
            .toList() ??
        <Property>[];
    final total = ((json['total'] ?? json['totalCount']) as num?)?.toInt() ??
        properties.length;
    final current =
        ((json['page'] ?? json['currentPage']) as num?)?.toInt() ?? page;
    final totalPages =
        ((json['total_pages'] ?? json['totalPages']) as num?)?.toInt() ?? 1;
    final resolvedLimit = ((json['limit'] ?? json['pageSize'] ?? limit)
            as num?)
        ?.toInt() ??
        limit;
    final filtersApplied = json['filters_applied'] ?? json['filters'];
    return UnifiedPropertyResponse(
      properties: properties,
      totalCount: total,
      currentPage: current,
      totalPages: totalPages,
      pageSize: resolvedLimit,
      filters: filtersApplied is Map
          ? Map<String, dynamic>.from(filtersApplied)
          : null,
    );
  }
}
