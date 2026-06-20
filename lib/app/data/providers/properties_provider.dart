import 'base_provider.dart';
import '../../utils/extensions/http_extensions.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';

class PropertiesProvider extends BaseProvider {
  Future<UnifiedPropertyResponse> explore({
    required double lat,
    required double lng,
    String? cursor,
    int limit = 20,
    double radiusKm = 10,
    Map<String, dynamic>? filters,
  }) async {
    final query = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      'limit': limit,
      if (radiusKm > 0 && !(filters?.containsKey('radius') ?? false))
        'radius': radiusKm,
      ...?filters,
    };
    final res = await get('/api/v1/properties/', query: query.asQueryParams());
    return handleResponse(res, (json) {
      final map = json as Map<String, dynamic>;
      final rawList = map['items'] as List?;
      final props =
          rawList
              ?.map(
                (e) => Property.fromJson(
                  _normalizeProperty(Map<String, dynamic>.from(e)),
                ),
              )
              .toList() ??
          <Property>[];
      final nextCursor = map['next_cursor'] as String?;
      final hasMore = (map['has_more'] as bool?) ?? (nextCursor != null);
      final resolvedLimit = (map['limit'] as num?)?.toInt() ?? limit;
      final filtersApplied = map['filters_applied'] ?? map['filters'];
      return UnifiedPropertyResponse(
        items: props,
        nextCursor: nextCursor,
        hasMore: hasMore,
        limit: resolvedLimit,
        filters: filtersApplied is Map
            ? Map<String, dynamic>.from(filtersApplied)
            : null,
      );
    });
  }

  Future<Property> getDetails(int id) async {
    final res = await get('/api/v1/properties/$id');
    return handleResponse(res, (json) {
      final map = json as Map<String, dynamic>;
      final data = map['data'] ?? map;
      return Property.fromJson(
        _normalizeProperty(Map<String, dynamic>.from(data)),
      );
    });
  }

  Future<List<Property>> recommendations({int limit = 10}) async {
    final res = await get(
      '/api/v1/properties/recommendations/',
      query: {'limit': '$limit'},
    );
    return handleResponse(res, (json) {
      // The recommendations endpoint is not cursor-paginated, so it may
      // return a bare list, {data: [...]}, or the new {items: [...]} envelope.
      final List<dynamic> rawList;
      if (json is List) {
        rawList = json;
      } else if (json is Map<String, dynamic>) {
        rawList = (json['items'] as List?) ??
            (json['data'] as List?) ??
            <dynamic>[];
      } else {
        rawList = <dynamic>[];
      }
      return rawList
          .map(
            (e) => Property.fromJson(
              _normalizeProperty(Map<String, dynamic>.from(e)),
            ),
          )
          .toList();
    });
  }

  Map<String, dynamic> _normalizeProperty(Map<String, dynamic> source) {
    final normalized = Map<String, dynamic>.from(source);
    final price =
        _coercePrice(normalized['daily_rate']) ??
        _coercePrice(normalized['base_price']) ??
        _coercePrice(normalized['monthly_rent']) ??
        0.0;
    normalized['daily_rate'] = price;
    normalized['currency'] ??= 'INR';
    normalized['property_type'] ??= 'property';
    normalized['city'] ??= '';
    normalized['country'] ??= 'Unknown';
    normalized['title'] ??= normalized['name'] ?? 'Property';
    return normalized;
  }

  double? _coercePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final sanitized = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
      if (sanitized.isEmpty) return null;
      return double.tryParse(sanitized);
    }
    return null;
  }
}
