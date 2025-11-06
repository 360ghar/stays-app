import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/property_model.dart';
import '../../data/repositories/properties_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../routes/app_routes.dart';
import '../../utils/logger/app_logger.dart';
import '../favorites_controller.dart';
import '../wishlist_controller.dart';

class ListingDetailController extends GetxController {
  final PropertiesRepository _repository;
  WishlistRepository? _wishlistRepository;

  ListingDetailController({
    required PropertiesRepository repository,
    WishlistRepository? wishlistRepository,
  }) : _repository = repository,
       _wishlistRepository = wishlistRepository {
    // Try to get wishlist repository if not provided
    if (_wishlistRepository == null) {
      try {
        _wishlistRepository = Get.find<WishlistRepository>();
      } catch (e) {
        AppLogger.warning(
          'WishlistRepository not found in dependency injection',
        );
      }
    }
    AppLogger.info(
      'ListingDetailController initialized with wishlist repository: ${_wishlistRepository != null}',
    );
  }

  final PageController galleryController = PageController();
  final Rxn<Property> listing = Rxn<Property>();
  final RxBool isLoading = false.obs;
  final RxInt currentImageIndex = 0.obs;
  late final FavoritesController _favoritesController =
      Get.find<FavoritesController>();
  String? _lastLoadedId;

  Future<void> load(String id) async {
    if (_lastLoadedId == id && listing.value != null) return;
    try {
      isLoading.value = true;
      final property = await _repository.getDetails(int.parse(id));
      setListing(property);
      _lastLoadedId = id;
    } finally {
      isLoading.value = false;
    }
  }

  void setListing(Property property) {
    final isFavorite =
        property.isFavorite == true ||
        property.liked == true ||
        _favoritesController.isFavorite(property.id);
    if (isFavorite) {
      _favoritesController.addFavorite(property.id);
    }
    listing.value = property.copyWith(isFavorite: isFavorite);
    currentImageIndex.value = 0;
    if (galleryController.hasClients) {
      galleryController.jumpToPage(0);
    }
  }

  void updateImageIndex(int index) {
    currentImageIndex.value = index;
  }

  Future<void> toggleFavorite(Property property) async {
    final propertyId = property.id;
    final isCurrentlyFavorite = _favoritesController.isFavorite(propertyId);

    if (_wishlistRepository == null) {
      AppLogger.error('WishlistRepository not available');
      Get.snackbar(
        'Error',
        'Wishlist service not available. Please try again.',
      );
      return;
    }

    try {
      if (isCurrentlyFavorite) {
        await _wishlistRepository!.remove(propertyId);
        _favoritesController.removeFavorite(propertyId);
      } else {
        await _wishlistRepository!.add(propertyId);
        _favoritesController.addFavorite(propertyId);
      }
      listing.value = listing.value?.copyWith(isFavorite: !isCurrentlyFavorite);

      try {
        final wishlistController = Get.find<WishlistController>();
        await wishlistController.loadWishlist(
          pageOverride: 1,
          showLoader: false,
        );
        AppLogger.info('Wishlist refreshed after toggle favorite');
      } catch (e) {
        AppLogger.info(
          'Wishlist controller not yet initialized, will refresh on navigation',
        );
      }

      Get.snackbar(
        isCurrentlyFavorite ? 'Removed from Wishlist' : 'Added to Wishlist',
        '${property.name} updated.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      AppLogger.error('Error toggling favorite', e);
      Get.snackbar('Error', 'Could not update wishlist. Please try again.');
    }
  }

  bool isPropertyFavorite(int propertyId) {
    return _favoritesController.isFavorite(propertyId);
  }

  void navigateToInquiryConfirmation(Property property) {
    Get.toNamed(Routes.inquiryConfirmation, arguments: property);
  }

  @override
  void onClose() {
    galleryController.dispose();
    super.onClose();
  }
}
