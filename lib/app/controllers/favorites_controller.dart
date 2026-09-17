import 'package:get/get.dart';

/// Canonical lightweight store of favorited property ids.
///
/// This is the shared id-set for the whole app. It holds no [Property]
/// objects, performs no network or Supabase I/O, and never talks to the
/// backend directly.
///
/// Sync roles (do not invert):
/// * Writer: [WishlistController] is the single backend-synced writer. It
///   mirrors server state into this store via [replaceAll], [addAll],
///   [addFavorite], [removeFavorite], and [clear] (write-through).
/// * Readers: Explore / home controllers and providers, the listing-detail
///   controller and view, and [FavoriteToggleMixin] read via [isFavorite] /
///   [favoriteIds] to render hearts and filter UI without touching the
///   wishlist repository.
///
/// NOT a shim: deleting it or migrating its importers to
/// `WishlistController` would invert the lightweight id-set pattern and force
/// Explore/Listing/mixin reads through the heavier paginated wishlist list.
/// It has 10+ importing files (explore/home bindings + controllers +
/// providers, listing detail controller + view, wishlist controller +
/// provider, favorite mixin) so any migration must be owned by those files,
/// not done as a drive-by delete.
class FavoritesController extends GetxController {
  FavoritesController();

  /// Reactive id-set. UIs wrap reads in `Obx` so heart icons update when the
  /// writer syncs.
  final RxSet<int> favoriteIds = <int>{}.obs;

  /// Read path. Called by Explore/Listing views and `FavoriteToggleMixin`
  /// (`isPropertyFavorite`) to render state. Never triggers a sync itself.
  bool isFavorite(int propertyId) => favoriteIds.contains(propertyId);

  /// Write-through target for `WishlistController.loadWishlist`: replaces the
  /// whole set with the fresh first page from the backend. Server is the
  /// source of truth; this store just mirrors it.
  void replaceAll(Iterable<int> ids) {
    favoriteIds.assignAll(ids);
  }

  /// Write-through target for `WishlistController.addToWishlist` (and the
  /// remove-failure rollback in `removeFromWishlist`) plus
  /// `FavoriteToggleMixin.toggleFavorite`: marks one id as favorited after
  /// the backend write succeeds (optimistic local path when no repository).
  void addFavorite(int propertyId) {
    favoriteIds.add(propertyId);
  }

  /// Write-through target for `WishlistController.loadMore` pagination:
  /// unions the next page's ids into the set without dropping earlier ones.
  void addAll(Iterable<int> ids) {
    favoriteIds.addAll(ids);
  }

  /// Write-through target for `WishlistController.removeFromWishlist` (and
  /// `clearAll` batch path) plus `FavoriteToggleMixin.toggleFavorite`:
  /// drops one id after the backend remove succeeds (optimistic when no
  /// repository).
  void removeFavorite(int propertyId) {
    favoriteIds.remove(propertyId);
  }

  /// Write-through target for `WishlistController.clearWishlist`: empties the
  /// set after the backend `clearAll` succeeds (or immediately when there is
  /// no repository). Only called from an explicit user "clear all" action.
  void clear() {
    favoriteIds.clear();
  }
}
