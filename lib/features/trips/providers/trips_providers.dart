import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/providers/data_providers.dart';
import 'package:stays_app/core/providers/session_provider.dart';

class TripsUiState {
  const TripsUiState({
    this.bookings = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error = '',
    this.nextCursor,
    this.hasMore = false,
    this.loadMoreFailed = false,
  });
  final List<Booking> bookings;
  final bool isLoading;
  final bool isLoadingMore;
  final String error;

  /// Cursor of the next page. Send it back unchanged.
  final String? nextCursor;
  final bool hasMore;

  /// The last next-page request failed. Scrolling does not retry it; the
  /// footer button does.
  final bool loadMoreFailed;

  bool get canLoadMore => hasMore && nextCursor != null && !isLoadingMore;

  TripsUiState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? nextCursor,
    bool? hasMore,
    bool? loadMoreFailed,
  }) {
    return TripsUiState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

final tripsProvider = NotifierProvider<TripsNotifier, TripsUiState>(
  TripsNotifier.new,
);

class TripsNotifier extends Notifier<TripsUiState> with AccountBound {
  @override
  TripsUiState build() {
    // Signed out: nothing to load. A new account starts from an empty state.
    if (watchAccount() == null) return const TripsUiState(isLoading: false);
    unawaited(Future(() => load()));
    return const TripsUiState();
  }

  Future<void> load({bool forceRefresh = false}) async {
    final sameAccount = accountGuard();
    if (state.bookings.isNotEmpty && !forceRefresh) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, error: '');
    try {
      // The server lists the newest booking first. The order is kept.
      final page = await ref.watch(bookingRepositoryProvider).fetchBookings();
      if (!sameAccount()) return;
      state = TripsUiState(
        bookings: page.items,
        isLoading: false,
        nextCursor: page.nextCursor,
        hasMore: page.hasNextPage,
      );
    } catch (e, s) {
      if (!sameAccount()) return;
      AppLogger.error('Trips v2: load failed', e, s);
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load your inquiries. Pull to retry.',
      );
    }
  }

  /// Reads the next page and appends it. It does nothing on the last page and
  /// while a page is loading.
  Future<void> loadMore() async {
    final sameAccount = accountGuard();
    final cursor = state.nextCursor;
    if (!state.canLoadMore || cursor == null) return;
    state = state.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await ref
          .watch(bookingRepositoryProvider)
          .fetchBookings(cursor: cursor);
      if (!sameAccount()) return;
      // A refresh finished meanwhile: this page belongs to the old list.
      if (state.nextCursor != cursor) return;
      state = TripsUiState(
        bookings: [...state.bookings, ...page.items],
        isLoading: false,
        nextCursor: page.nextCursor,
        hasMore: page.hasNextPage,
      );
    } catch (e, s) {
      if (!sameAccount()) return;
      AppLogger.error('Trips v2: loadMore failed', e, s);
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  Future<void> refresh() => load(forceRefresh: true);
}
