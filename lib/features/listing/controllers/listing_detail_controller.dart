import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/properties_repository.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/features/wishlist/controllers/wishlist_controller.dart';
import 'package:stays_app/app/data/services/image_prefetch_service.dart';

class ListingDetailController extends BaseController {
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
  final RxInt currentImageIndex = 0.obs;
  late final FavoritesController _favoritesController =
      Get.find<FavoritesController>();
  String? _lastLoadedId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Property) {
      setListing(args);
    }

    final idParam = Get.parameters['id'];
    final parsedId = int.tryParse(idParam ?? '');
    if (parsedId == null) {
      errorMessage.value = 'Invalid listing ID';
      return;
    }

    // Refresh details in background if we already have a partial listing
    final shouldShowLoader = listing.value == null;
    load(parsedId, showLoader: shouldShowLoader);
  }

  Future<void> load(int id, {bool showLoader = true}) async {
    final idStr = id.toString();
    if (_lastLoadedId == idStr && listing.value != null) return;
    await executeWithErrorHandling(
      () async {
        final property = await _repository.getDetails(id);
        setListing(property);
        _lastLoadedId = idStr;

        // Prefetch all gallery images
        _prefetchGalleryImages(property);
      },
      showLoading: showLoader,
    );
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
    
    // Prefetch adjacent images when user swipes
    _prefetchAdjacentImages(index);
  }

  /// Prefetch all gallery images for the property
  void _prefetchGalleryImages(Property property) {
    if (!Get.isRegistered<ImagePrefetchService>()) return;
    
    try {
      Get.find<ImagePrefetchService>().prefetchPropertyDetailImages(property);
    } catch (e) {
      AppLogger.debug('Failed to prefetch gallery images: $e');
    }
  }

  /// Prefetch images adjacent to the current index
  void _prefetchAdjacentImages(int currentIndex) {
    if (!Get.isRegistered<ImagePrefetchService>()) return;
    
    final property = listing.value;
    if (property == null) return;
    
    final images = property.images ?? [];
    if (images.isEmpty) return;
    
    final prefetchService = Get.find<ImagePrefetchService>();
    
    // Prefetch next 2 images
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < images.length) {
        prefetchService.prefetchImage(images[nextIndex].imageUrl);
      }
    }
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
