import 'property_model.dart';

/// Cursor-paginated response envelope.
///
/// Backend contract (source of truth):
///   {items: [...], next_cursor: base64-or-null, has_more: bool, limit: int}
///
/// `next_cursor` is null on the terminal page. End-of-list is detected via
/// `has_more == false`. Cursor tokens are opaque base64; never decode them.
class UnifiedPropertyResponse {
  final List<Property> items;
  final String? nextCursor;
  final bool hasMore;
  final int limit;
  final Map<String, dynamic>? filters;

  /// True when the server indicates more pages exist and a cursor is available.
  bool get hasNextPage => hasMore && nextCursor != null;

  UnifiedPropertyResponse({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.limit,
    this.filters,
  });

  factory UnifiedPropertyResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    final props =
        rawItems
            ?.map((e) => Property.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        <Property>[];
    final nextCursor = json['next_cursor'] as String?;
    final hasMore = (json['has_more'] as bool?) ?? (nextCursor != null);
    final resolvedLimit = (json['limit'] as num?)?.toInt() ?? 20;
    final filtersApplied = json['filters_applied'] ?? json['filters'];
    return UnifiedPropertyResponse(
      items: props,
      nextCursor: nextCursor,
      hasMore: hasMore,
      limit: resolvedLimit,
      filters: filtersApplied is Map
          ? Map<String, dynamic>.from(filtersApplied)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'next_cursor': nextCursor,
    'has_more': hasMore,
    'limit': limit,
    if (filters != null) 'filters': filters,
  };
}
