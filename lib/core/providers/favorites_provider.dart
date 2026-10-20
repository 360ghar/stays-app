import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/core/providers/session_provider.dart';

/// Canonical lightweight store of favorited property ids.
///
/// Replaces the legacy GetX `FavoritesController`. Holds no [Property]
/// objects, performs no network I/O, and never talks to the backend
/// directly. The wishlist flows mirror server state into this store
/// (write-through); Explore / Listing views read via [isFavorite] to render
/// hearts without touching the wishlist repository.
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    // The set belongs to one account. It starts empty for the next one.
    ref.watch(accountIdProvider);
    return <int>{};
  }

  bool isFavorite(int propertyId) => state.contains(propertyId);

  /// Replaces the whole set with the fresh page from the backend. Server is
  /// the source of truth; this store just mirrors it.
  void replaceAll(Iterable<int> ids) {
    state = Set<int>.of(ids);
  }

  /// Unions the next page's ids into the set without dropping earlier ones.
  void addAll(Iterable<int> ids) {
    state = {...state, ...ids};
  }

  void addFavorite(int propertyId) {
    if (state.contains(propertyId)) return;
    state = {...state, propertyId};
  }

  void removeFavorite(int propertyId) {
    if (!state.contains(propertyId)) return;
    state = state.where((id) => id != propertyId).toSet();
  }

  void clear() {
    if (state.isEmpty) return;
    state = <int>{};
  }
}
