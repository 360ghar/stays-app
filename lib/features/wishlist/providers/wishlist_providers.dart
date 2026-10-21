import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/core/providers/favorites_provider.dart';
import 'package:stays_app/core/providers/session_provider.dart';

class WishlistUiState {
  const WishlistUiState({
    this.items = const [],
    this.isLoading = true,
    this.isRefreshing = false,
    this.error = '',
    this.nextCursor,
    this.hasMore = false,
  });
  final List<Property> items;
  final bool isLoading;
  final bool isRefreshing;
  final String error;
  final String? nextCursor;
  final bool hasMore;

  WishlistUiState copyWith({
    List<Property>? items,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    String? nextCursor,
    bool? hasMore,
  }) {
    return WishlistUiState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, WishlistUiState>(
  WishlistNotifier.new,
);

class WishlistNotifier extends Notifier<WishlistUiState> with AccountBound {
  String? _pagingCursor;

  /// Bumped by clearAll: a load that started before it must not repopulate
  /// the cleared list.
  int _clearGeneration = 0;
  @override
  WishlistUiState build() {
    _pagingCursor = null;
    // Signed out: nothing to load. A new account starts from an empty state.
    if (watchAccount() == null) return const WishlistUiState(isLoading: false);
    unawaited(Future(() => load()));
    return const WishlistUiState();
  }

  WishlistRepository get _repo => ref.watch(wishlistRepositoryProvider);

  Future<void> load() async {
    final sameAccount = accountGuard();
    final generation = _clearGeneration;
    state = state.copyWith(isLoading: true, error: '');
    try {
      final resp = await _repo.listFavorites();
      if (!sameAccount() || generation != _clearGeneration) return;
      ref
          .read(favoritesProvider.notifier)
          .replaceAll(resp.items.map((p) => p.id));
      state = WishlistUiState(
        isLoading: false,
        items: List<Property>.from(resp.items),
        hasMore: resp.hasMore,
        nextCursor: resp.nextCursor,
      );
    } catch (e, s) {
      if (!sameAccount()) return;
      AppLogger.error('Wishlist v2: load failed', e, s);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load wishlist.',
        items: const [],
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    await load();
    state = state.copyWith(isRefreshing: false);
  }

  Future<void> loadMore() async {
    final sameAccount = accountGuard();
    final generation = _clearGeneration;
    final cursor = state.nextCursor;
    if (!state.hasMore || cursor == null) return;
    // Scroll end fires repeatedly; one fetch per cursor (audit duplicate
    // inserts when the same page resolves twice).
    if (_pagingCursor == cursor) return;
    _pagingCursor = cursor;
    try {
      final resp = await _repo.listFavorites(cursor: cursor);
      if (!sameAccount() || generation != _clearGeneration) return;
      ref.read(favoritesProvider.notifier).addAll(resp.items.map((p) => p.id));
      state = state.copyWith(
        items: [...state.items, ...resp.items],
        nextCursor: resp.nextCursor,
        hasMore: resp.hasMore,
      );
    } catch (e, s) {
      AppLogger.error('Wishlist v2: loadMore failed', e, s);
    } finally {
      if (sameAccount()) _pagingCursor = null;
    }
  }

  Future<void> remove(int propertyId) async {
    final sameAccount = accountGuard();
    final index = state.items.indexWhere((p) => p.id == propertyId);
    final removed = index != -1 ? state.items[index] : null;
    if (index != -1) {
      final next = [...state.items]..removeAt(index);
      state = state.copyWith(items: next);
    }
    ref.read(favoritesProvider.notifier).removeFavorite(propertyId);
    try {
      await _repo.remove(propertyId);
    } catch (e, s) {
      if (!sameAccount()) return;
      AppLogger.error('Wishlist v2: remove failed', e, s);
      if (removed != null) {
        final next = [...state.items];
        next.insert(index.clamp(0, next.length), removed);
        state = state.copyWith(items: next);
      }
      ref.read(favoritesProvider.notifier).addFavorite(propertyId);
    }
  }

  /// Removes every liked property, not only the pages on screen: it follows
  /// `next_cursor` to collect the ids that are not loaded yet.
  Future<void> clearAll() async {
    final sameAccount = accountGuard();
    _clearGeneration++;
    final ids = state.items.map((p) => p.id).toList();
    var cursor = state.hasMore ? state.nextCursor : null;
    state = const WishlistUiState(isLoading: false);
    ref.read(favoritesProvider.notifier).clear();
    try {
      while (cursor != null) {
        final page = await _repo.listFavorites(cursor: cursor, limit: 100);
        if (!sameAccount()) return;
        ids.addAll(page.items.map((p) => p.id));
        cursor = page.hasMore ? page.nextCursor : null;
      }
      if (ids.isNotEmpty) await _repo.clearAll(ids);
    } catch (e, s) {
      if (!sameAccount()) return;
      AppLogger.error('Wishlist v2: clearAll failed', e, s);
      await load();
    }
  }
}
