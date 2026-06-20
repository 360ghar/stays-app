import 'dart:async';

import 'package:get/get.dart';

import 'base_controller.dart';

/// Generic cursor-based pagination controller for list-based views.
///
/// Subclasses implement [fetchPage] which receives an opaque cursor (null on
/// the first page) and returns the page of items plus the server-provided
/// `nextCursor` and `hasMore` flag. Page-index arithmetic is intentionally
/// avoided: the cursor is the only pagination token.
abstract class PaginatedController<T> extends BaseController {
  final RxList<T> items = <T>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  @override
  RxBool get isLoading => _isLoading;
  final RxBool hasMore = true.obs;
  final RxnString nextCursor = RxnString(null);
  final int pageSize;

  PaginatedController({this.pageSize = 20});

  /// Fetches a single page of items.
  ///
  /// [cursor] is null on the first page and an opaque base64 token on
  /// subsequent pages. Returns a record containing the page items, the next
  /// cursor (null on the terminal page) and whether more pages exist.
  Future<({List<T> items, String? nextCursor, bool hasMore})> fetchPage({
    required String? cursor,
    required int limit,
  });

  Future<void> refreshList() async {
    if (isRefreshing.value) return;
    try {
      isRefreshing.value = true;
      final result = await fetchPage(cursor: null, limit: pageSize);
      items.assignAll(result.items);
      nextCursor.value = result.nextCursor;
      hasMore.value = result.hasMore;
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoading.value || !hasMore.value) return;
    final cursor = nextCursor.value;
    if (cursor == null) {
      hasMore.value = false;
      return;
    }
    try {
      _isLoading.value = true;
      final result = await fetchPage(cursor: cursor, limit: pageSize);
      if (result.items.isEmpty) {
        hasMore.value = false;
        nextCursor.value = null;
        return;
      }
      items.addAll(result.items);
      nextCursor.value = result.nextCursor;
      hasMore.value = result.hasMore;
    } finally {
      _isLoading.value = false;
    }
  }
}
