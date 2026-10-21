import 'package:flutter/foundation.dart' show debugPrint;

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
          for (final item in rawItems) ?_parseItem(item, parse),
      ],
      nextCursor: nextCursor is String && nextCursor.isNotEmpty
          ? nextCursor
          : null,
      hasMore: json['has_more'] == true,
      limit: limit is num ? limit.toInt() : 0,
      total: total is num ? total.toInt() : null,
    );
  }

  /// A row that is not an object, or that fails to parse, is skipped and
  /// reported: one bad row must not fail the whole page.
  static T? _parseItem<T>(
    Object? item,
    T Function(Map<String, dynamic> item) parse,
  ) {
    if (item is! Map) {
      debugPrint('CursorPage: skipped a list item that is not an object');
      return null;
    }
    try {
      return parse(Map<String, dynamic>.from(item));
    } catch (error) {
      debugPrint('CursorPage: skipped a malformed list item: $error');
      return null;
    }
  }

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
  final int limit;
  final int? total;

  /// True when another page can be read. The flag and the cursor must agree.
  bool get hasNextPage => hasMore && nextCursor != null;
}
