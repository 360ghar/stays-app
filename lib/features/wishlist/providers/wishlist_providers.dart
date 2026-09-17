import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/controllers/favorites_controller.dart';
import 'package:stays_app/app/data/models/property_model.dart';
import 'package:stays_app/app/data/repositories/wishlist_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

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

class WishlistNotifier extends Notifier<WishlistUiState> {
  String? _pagingCursor;
  @override
  WishlistUiState build() {
    unawaited(Future(() => load()));
    return const WishlistUiState();
  }

  WishlistRepository? get _repo => Get.isRegistered<WishlistRepository>()
      ? Get.find<WishlistRepository>()
      : null;

  FavoritesController? get _favorites => Get.isRegistered<FavoritesController>()
      ? Get.find<FavoritesController>()
      : null;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: '');
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Wishlist service unavailable.',
        items: const [],
      );
      return;
    }
    try {
      final resp = await repo.listFavorites();
      _favorites?.replaceAll(resp.items.map((p) => p.id));
      state = WishlistUiState(
        items: List<Property>.from(resp.items),
        hasMore: resp.hasMore,
        nextCursor: resp.nextCursor,
      );
    } catch (e, s) {
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
    final repo = _repo;
    final cursor = state.nextCursor;
    if (repo == null || !state.hasMore || cursor == null) return;
    // Scroll end fires repeatedly; one fetch per cursor (audit duplicate
    // inserts when the same page resolves twice).
    if (_pagingCursor == cursor) return;
    _pagingCursor = cursor;
    try {
      final resp = await repo.listFavorites(cursor: cursor);
      _favorites?.addAll(resp.items.map((p) => p.id));
      state = state.copyWith(
        items: [...state.items, ...resp.items],
        nextCursor: resp.nextCursor,
        hasMore: resp.hasMore,
      );
    } catch (e, s) {
      AppLogger.error('Wishlist v2: loadMore failed', e, s);
    } finally {
      _pagingCursor = null;
    }
  }

  Future<void> remove(int propertyId) async {
    final index = state.items.indexWhere((p) => p.id == propertyId);
    final removed = index != -1 ? state.items[index] : null;
    if (index != -1) {
      final next = [...state.items]..removeAt(index);
      state = state.copyWith(items: next);
    }
    _favorites?.removeFavorite(propertyId);
    try {
      await _repo?.remove(propertyId);
    } catch (e, s) {
      AppLogger.error('Wishlist v2: remove failed', e, s);
      if (removed != null) {
        final next = [...state.items];
        next.insert(index.clamp(0, next.length), removed);
        state = state.copyWith(items: next);
      }
      _favorites?.addFavorite(propertyId);
    }
  }

  Future<void> clearAll() async {
    final repo = _repo;
    if (repo == null) return;
    final ids = state.items.map((p) => p.id).toList();
    state = state.copyWith(items: const []);
    _favorites?.clear();
    try {
      if (ids.isNotEmpty) await repo.clearAll(ids);
    } catch (e, s) {
      AppLogger.error('Wishlist v2: clearAll failed', e, s);
      await load();
    }
  }
}
