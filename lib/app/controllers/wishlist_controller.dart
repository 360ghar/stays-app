import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

import 'filter_controller.dart';

class WishlistController extends GetxController {
  WishlistRepository? _wishlistRepository;
  FilterController? _filterController;

  final RxList<Property> wishlistItems = <Property>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt pageSize = 20.obs;
  final RxInt totalCount = 0.obs;

  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;
  Worker? _filterWorker;
  final Set<int> _favoriteIds = <int>{};

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _initializeFilterSync();
    loadWishlist();
  }

  void _initializeServices() {
    try {
      _wishlistRepository = Get.find<WishlistRepository>();
    } catch (e) {
      AppLogger.warning('WishlistRepository not found');
    }
  }

  void _initializeFilterSync() {
    if (!Get.isRegistered<FilterController>()) {
      AppLogger.warning('FilterController not available for wishlist');
      return;
    }
    _filterController = Get.find<FilterController>();
    _activeFilters = _filterController!.filterFor(FilterScope.wishlist);
    _filterWorker = debounce<UnifiedFilterModel>(
      _filterController!.rxFor(FilterScope.wishlist),
      (filters) async {
        if (_activeFilters == filters) return;
        _activeFilters = filters;
        await loadWishlist(pageOverride: 1);
      },
      time: const Duration(milliseconds: 160),
    );
  }

  @override
  void onClose() {
    _filterWorker?.dispose();
    super.onClose();
  }

  Map<String, dynamic>? _buildFilterQuery() {
    final query = _activeFilters.toQueryParameters();
    return query.isEmpty ? null : query;
  }

  Future<void> loadWishlist({int? pageOverride, bool showLoader = true}) async {
    if (_wishlistRepository == null) {
      errorMessage.value = 'Wishlist service unavailable';
      wishlistItems.clear();
      return;
    }
    final targetPage = pageOverride ?? currentPage.value;
    if (targetPage < 1) {
      await loadWishlist(pageOverride: 1, showLoader: showLoader);
      return;
    }
    if (showLoader) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }
    errorMessage.value = '';
    try {
      final response = await _wishlistRepository!.listFavorites(
        page: targetPage,
        limit: pageSize.value,
        filters: _buildFilterQuery(),
      );
      currentPage.value = response.currentPage;
      totalPages.value = response.totalPages;
      totalCount.value = response.totalCount;
      pageSize.value = response.pageSize;
      wishlistItems.assignAll(response.properties);
      _favoriteIds.addAll(response.properties.map((e) => e.id));
    } catch (e) {
      errorMessage.value = 'Failed to load wishlist';
      AppLogger.error('Error loading wishlist', e);
      if (pageOverride != null && pageOverride > 1) {
        currentPage.value = pageOverride - 1;
      }
      wishlistItems.clear();
    } finally {
      if (showLoader) {
        isLoading.value = false;
      } else {
        isRefreshing.value = false;
      }
    }
  }

  @override
  Future<void> refresh() async {
    await loadWishlist(showLoader: false);
  }

  Future<void> goToPage(int page) async {
    if (page == currentPage.value) return;
    if (page < 1 || page > totalPages.value) return;
    await loadWishlist(pageOverride: page);
  }

  Future<void> nextPage() async {
    if (currentPage.value >= totalPages.value) return;
    await goToPage(currentPage.value + 1);
  }

  Future<void> previousPage() async {
    if (currentPage.value <= 1) return;
    await goToPage(currentPage.value - 1);
  }

  Future<void> addToWishlist(Property property) async {
    if (isInWishlist(property.id)) return;
    if (_wishlistRepository == null) {
      wishlistItems.insert(0, property);
      totalCount.value = wishlistItems.length;
      _favoriteIds.add(property.id);
      Get.snackbar(
        'Added to Wishlist',
        '${property.name} has been added to your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    try {
      await _wishlistRepository!.add(property.id);
      _favoriteIds.add(property.id);
      await loadWishlist(pageOverride: currentPage.value);
      Get.snackbar(
        'Added to Wishlist',
        '${property.name} has been added to your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('Error adding to wishlist', e);
      Get.snackbar(
        'Error',
        'Failed to add to wishlist. Please try again.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> removeFromWishlist(int propertyId) async {
    Property? property;
    if (_wishlistRepository == null) {
      property =
          wishlistItems.firstWhereOrNull((p) => p.id == propertyId);
      wishlistItems.removeWhere((p) => p.id == propertyId);
      _favoriteIds.remove(propertyId);
      totalCount.value = wishlistItems.length;
      Get.snackbar(
        'Removed from Wishlist',
        property != null
            ? '${property.name} has been removed from your wishlist'
            : 'Item has been removed from your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    property = wishlistItems.firstWhereOrNull((p) => p.id == propertyId);
    try {
      await _wishlistRepository!.remove(propertyId);
      _favoriteIds.remove(propertyId);
      await loadWishlist(pageOverride: currentPage.value);
      Get.snackbar(
        'Removed from Wishlist',
        property != null
            ? '${property.name} has been removed from your wishlist'
            : 'Item has been removed from your wishlist',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      AppLogger.error('Error removing from wishlist', e);
      Get.snackbar(
        'Error',
        'Failed to remove from wishlist. Please try again.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  bool isInWishlist(int propertyId) => _favoriteIds.contains(propertyId);

  Future<void> toggleWishlist(Property property) async {
    if (isInWishlist(property.id)) {
      await removeFromWishlist(property.id);
    } else {
      await addToWishlist(property);
    }
  }

  void clearWishlist() {
    Get.dialog(
      AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text(
          'Are you sure you want to remove all items from your wishlist?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              if (_wishlistRepository != null) {
                try {
                  for (final item in wishlistItems.toList()) {
                    await _wishlistRepository!.remove(item.id);
                  }
                  _favoriteIds.clear();
                  await loadWishlist(pageOverride: 1);
                  Get.snackbar(
                    'Wishlist Cleared',
                    'All items have been removed from your wishlist',
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                  );
                } catch (e) {
                  AppLogger.error('Error clearing wishlist', e);
                  Get.snackbar(
                    'Error',
                    'Failed to clear wishlist. Please try again.',
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                  );
                }
              } else {
                wishlistItems.clear();
                _favoriteIds.clear();
                totalCount.value = 0;
                Get.snackbar(
                  'Wishlist Cleared',
                  'All items have been removed from your wishlist',
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  bool get hasActiveFilters => _activeFilters.isNotEmpty;

  int get totalItems => totalCount.value;
}





