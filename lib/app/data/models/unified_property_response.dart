import 'cursor_page.dart';
import 'property_model.dart';

/// One page of properties from `GET /api/v1/properties` or `GET /api/v1/swipes`.
///
/// Backend contract (source of truth):
///   {items: [...], next_cursor: string-or-null, has_more: bool, limit: int,
///    total: int-or-null}
///
/// `next_cursor` is null on the terminal page. End-of-list is detected via
/// `has_more == false`. Cursor tokens are opaque; never decode them.
class UnifiedPropertyResponse {
  UnifiedPropertyResponse({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    required this.limit,
    this.total,
    this.noStore = false,
  });

  /// Reads a `CursorPage[Property]` body. [noStore] is true when the response
  /// said `Cache-Control: no-store`.
  factory UnifiedPropertyResponse.fromJson(
    Object? json, {
    bool noStore = false,
  }) {
    final page = CursorPage.fromJson(json, Property.fromJson);
    return UnifiedPropertyResponse(
      items: page.items,
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
      limit: page.limit,
      total: page.total,
      noStore: noStore,
    );
  }

  final List<Property> items;
  final String? nextCursor;
  final bool hasMore;
  final int limit;
  final int? total;

  /// True when the response said `Cache-Control: no-store`. It must not be
  /// written to a local cache.
  final bool noStore;

  /// True when the server indicates more pages exist and a cursor is
  /// available. Both flags must agree before paging: [hasMore] is the
  /// authoritative "are there more" signal, and [nextCursor] is the token
  /// the server expects on the next call. If they disagree, treat it as
  /// "end of list" rather than risk an infinite loop or a missed page.
  bool get hasNextPage => hasMore && nextCursor != null;
}
