import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/helpers/haptic_helper.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Result of a favorite toggle operation.
class FavoriteToggleResult {
  const FavoriteToggleResult({
    required this.success,
    required this.newFavoriteState,
    this.errorMessage,
  });

  const FavoriteToggleResult.success({required this.newFavoriteState})
      : success = true,
        errorMessage = null;

  const FavoriteToggleResult.failure(this.errorMessage)
      : success = false,
        newFavoriteState = false;

  final bool success;
  final bool newFavoriteState;
  final String? errorMessage;
}

/// Mixin that provides consistent favorite toggle functionality across controllers.
///
/// Controllers using this mixin must provide access to [WishlistRepository]
/// and [FavoritesController] via the abstract getters.
///
/// Example usage:
/// ```dart
/// class MyController extends BaseController with FavoriteToggleMixin {
///   final WishlistRepository _wishlistRepo;
///   final FavoritesController _favoritesCtrl;
///
///   @override
///   WishlistRepository? get wishlistRepository => _wishlistRepo;
///
///   @override
///   FavoritesController get favoritesController => _favoritesCtrl;
/// }
/// ```
mixin FavoriteToggleMixin on GetxController {
  /// The wishlist repository for API calls. May be null if unavailable.
  WishlistRepository? get wishlistRepository;

  /// The favorites controller for managing favorite state.
  FavoritesController get favoritesController;

  /// Whether to show snackbar notifications on toggle. Override to disable.
  bool get showFavoriteSnackbars => true;

  /// Whether to trigger haptic feedback on toggle. Override to disable.
  bool get enableFavoriteHaptics => true;

  /// Check if a property is currently favorited.
  bool isPropertyFavorite(int propertyId) {
    return favoritesController.isFavorite(propertyId);
  }

  /// Toggle the favorite status of a property.
  ///
  /// Returns a [FavoriteToggleResult] indicating success/failure and new state.
  ///
  /// [onSuccess] is called after a successful toggle with the new favorite state.
  /// Use this to update local UI state in the controller.
  Future<FavoriteToggleResult> toggleFavorite(
    Property property, {
    VoidCallback? onSuccess,
  }) async {
    final propertyId = property.id;
    final wasCurrentlyFavorite = favoritesController.isFavorite(propertyId);

    if (enableFavoriteHaptics) {
      unawaited(HapticHelper.favoriteToggle());
    }

    final repo = wishlistRepository;
    if (repo == null) {
      AppLogger.error('WishlistRepository not available for toggleFavorite');
      _showSnackbar(
        'Error',
        'Wishlist service not available. Please try again.',
        isError: true,
      );
      return const FavoriteToggleResult.failure(
        'Wishlist service not available',
      );
    }

    try {
      if (wasCurrentlyFavorite) {
        await repo.remove(propertyId);
        favoritesController.removeFavorite(propertyId);
      } else {
        await repo.add(propertyId);
        favoritesController.addFavorite(propertyId);
      }

      final newFavoriteState = !wasCurrentlyFavorite;

      // Call success callback for controller-specific UI updates
      onSuccess?.call();

      _showSnackbar(
        wasCurrentlyFavorite ? 'Removed from Wishlist' : 'Added to Wishlist',
        '${property.name} updated.',
      );

      return FavoriteToggleResult.success(newFavoriteState: newFavoriteState);
    } catch (e) {
      AppLogger.error('Error toggling favorite for property $propertyId', e);
      _showSnackbar(
        'Error',
        'Could not update wishlist. Please try again.',
        isError: true,
      );
      return FavoriteToggleResult.failure(e.toString());
    }
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    if (!showFavoriteSnackbars) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: isError ? Colors.red.withValues(alpha: 0.9) : null,
      colorText: isError ? Colors.white : null,
    );
  }
}
