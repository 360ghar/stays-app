import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/models/unified_filter_model.dart';
import 'package:stays_app/app/data/models/unified_property_response.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

import 'package:stays_app/app/controllers/filter_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';

class WishlistController extends BaseController {
  WishlistRepository? _wishlistRepository;
  FilterController? _filterController;

  final RxList<Property> wishlistItems = <Property>[].obs;
  final RxBool isRefreshing = false.obs;
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt pageSize = 20.obs;
  final RxInt totalCount = 0.obs;

  UnifiedFilterModel _activeFilters = UnifiedFilterModel.empty;
  FavoritesController? _favoritesController;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _initializeFilterSync();
    loadWishlist();
  }

  @override
  void onReady() {
    super.onReady();
    // Ensure wishlist is refreshed when controller becomes active
    loadWishlist(pageOverride: 1, showLoader: false);
  }

  void _initializeServices() {
    try {
      _wishlistRepository = Get.find<WishlistRepository>();
    } catch (e) {
      AppLogger.warning('WishlistRepository not found');
    }
    try {
      _favoritesController = Get.find<FavoritesController>();
    } catch (e) {
      AppLogger.warning('FavoritesController not found');
    }
  }

  void _initializeFilterSync() {
    if (!Get.isRegistered<FilterController>()) {
      AppLogger.warning('FilterController not available for wishlist');
      return;
    }
    _filterController = Get.find<FilterController>();
    _activeFilters = _filterController!.filterFor(FilterScope.wishlist);
    trackWorker(debounce<UnifiedFilterModel>(
      _filterController!.rxFor(FilterScope.wishlist),
      (filters) async {
        if (_activeFilters == filters) return;
        _activeFilters = filters;
        await loadWishlist(pageOverride: 1);
      },
      time: const Duration(milliseconds: 160),
    ));
  }

  @override
  void onClose() {
    // Worker is automatically disposed by BaseController via trackWorker
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
      final UnifiedPropertyResponse response = await _wishlistRepository!
          .listFavorites(
            page: targetPage,
            limit: pageSize.value,
            filters: _buildFilterQuery(),
          );
      currentPage.value = response.currentPage;
      totalPages.value = response.totalPages;
      totalCount.value = response.totalCount;
      pageSize.value = response.pageSize;
      final List<Property> fetchedProperties = List<Property>.from(
        response.properties,
      );
      wishlistItems.assignAll(fetchedProperties);
      if (targetPage == 1) {
        _favoritesController?.replaceAll(
          fetchedProperties.map((property) => property.id),
        );
      } else {
        _favoritesController?.addAll(
          fetchedProperties.map((property) => property.id),
        );
      }
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
      _favoritesController?.addFavorite(property.id);
      AppSnackbar.success(
        title: 'Added to Wishlist',
        message: '${property.name} has been added to your wishlist',
      );
      return;
    }
    try {
      await _wishlistRepository!.add(property.id);
      _favoritesController?.addFavorite(property.id);
      await loadWishlist(pageOverride: currentPage.value);
      AppSnackbar.success(
        title: 'Added to Wishlist',
        message: '${property.name} has been added to your wishlist',
      );
    } catch (e) {
      AppLogger.error('Error adding to wishlist', e);
      AppSnackbar.error(
        title: 'Error',
        message: 'Failed to add to wishlist. Please try again.',
      );
    }
  }

  Future<void> removeFromWishlist(int propertyId) async {
    final propertyIndex = wishlistItems.indexWhere(
      (property) => property.id == propertyId,
    );
    final property = propertyIndex != -1 ? wishlistItems[propertyIndex] : null;

    void showRemovalSnackbar() {
      AppSnackbar.success(
        title: 'Removed from Wishlist',
        message: property != null
            ? '${property.name} has been removed from your wishlist'
            : 'Item has been removed from your wishlist',
      );
    }

    if (_wishlistRepository == null) {
      if (propertyIndex != -1) {
        wishlistItems.removeAt(propertyIndex);
      }
      totalCount.value = wishlistItems.length;
      _favoritesController?.removeFavorite(propertyId);
      showRemovalSnackbar();
      return;
    }

    Property? removedProperty;
    int? removedIndex;
    if (propertyIndex != -1) {
      removedProperty = property;
      removedIndex = propertyIndex;
      wishlistItems.removeAt(propertyIndex);
      if (totalCount.value > 0) {
        totalCount.value = totalCount.value - 1;
      }
    }
    _favoritesController?.removeFavorite(propertyId);

    try {
      await _wishlistRepository!.remove(propertyId);
      await loadWishlist(pageOverride: currentPage.value, showLoader: false);
      showRemovalSnackbar();
    } catch (e) {
      AppLogger.error('Error removing from wishlist', e);
      if (removedProperty != null && removedIndex != null) {
        if (removedIndex <= wishlistItems.length) {
          wishlistItems.insert(removedIndex, removedProperty);
        } else {
          wishlistItems.add(removedProperty);
        }
        totalCount.value = totalCount.value + 1;
        _favoritesController?.addFavorite(propertyId);
      }
      AppSnackbar.error(
        title: 'Error',
        message: 'Failed to remove from wishlist. Please try again.',
      );
    }
  }

  bool isInWishlist(int propertyId) =>
      _favoritesController?.isFavorite(propertyId) ??
      wishlistItems.any((p) => p.id == propertyId);

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
                  _favoritesController?.clear();
                  await loadWishlist(pageOverride: 1);
                  AppSnackbar.success(
                    title: 'Wishlist Cleared',
                    message: 'All items have been removed from your wishlist',
                  );
                } catch (e) {
                  AppLogger.error('Error clearing wishlist', e);
                  AppSnackbar.error(
                    title: 'Error',
                    message: 'Failed to clear wishlist. Please try again.',
                  );
                }
              } else {
                wishlistItems.clear();
                _favoritesController?.clear();
                totalCount.value = 0;
                AppSnackbar.success(
                  title: 'Wishlist Cleared',
                  message: 'All items have been removed from your wishlist',
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
