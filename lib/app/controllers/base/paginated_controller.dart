import 'dart:async';

import 'package:get/get.dart';

import 'base_controller.dart';

/// Generic pagination controller for list-based views.
abstract class PaginatedController<T> extends BaseController {
  final RxList<T> items = <T>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  @override
  RxBool get isLoading => _isLoading;
  final RxBool hasMore = true.obs;
  final RxInt currentPage = 1.obs;
  final int pageSize;

  PaginatedController({this.pageSize = 20});

  Future<List<T>> fetchPage({required int page, required int limit});

  Future<void> refreshList() async {
    if (isRefreshing.value) return;
    try {
      isRefreshing.value = true;
      currentPage.value = 1;
      final data = await fetchPage(page: 1, limit: pageSize);
      items.assignAll(data);
      hasMore.value = data.length == pageSize;
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoading.value || !hasMore.value) return;
    try {
      _isLoading.value = true;
      final next = currentPage.value + 1;
      final data = await fetchPage(page: next, limit: pageSize);
      if (data.isEmpty) {
        hasMore.value = false;
        return;
      }
      items.addAll(data);
      currentPage.value = next;
      hasMore.value = data.length == pageSize;
    } finally {
      _isLoading.value = false;
    }
  }
}
