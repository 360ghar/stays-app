/// One page of a backend list: `{items, next_cursor, has_more, limit, total}`.
///
/// `next_cursor` is opaque. Send it back unchanged, with the same filters, to
/// read the next page. `total` is null unless the request set
/// `include_total=true`.
class CursorPage<T> {
  const CursorPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.limit,
    this.total,
  });

  factory CursorPage.fromJson(
    Object? json,
    T Function(Map<String, dynamic> item) parse,
  ) {
    if (json is! Map) {
      throw const FormatException('A list response must be a JSON object.');
    }
    final rawItems = json['items'];
    final nextCursor = json['next_cursor'];
    final limit = json['limit'];
    final total = json['total'];
    return CursorPage<T>(
      items: [
        if (rawItems is List)
          for (final item in rawItems)
            if (item is Map) parse(Map<String, dynamic>.from(item)),
      ],
      nextCursor: nextCursor is String && nextCursor.isNotEmpty
          ? nextCursor
          : null,
      hasMore: json['has_more'] == true,
      limit: limit is num ? limit.toInt() : 0,
      total: total is num ? total.toInt() : null,
    );
  }

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
  final int limit;
  final int? total;

  /// True when another page can be read. The flag and the cursor must agree.
  bool get hasNextPage => hasMore && nextCursor != null;
}
