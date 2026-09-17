import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/providers/data_providers.dart';

class TripsUiState {
  const TripsUiState({
    this.bookings = const [],
    this.isLoading = true,
    this.error = '',
  });
  final List<Booking> bookings;
  final bool isLoading;
  final String error;

  TripsUiState copyWith({
    List<Booking>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return TripsUiState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final tripsProvider = NotifierProvider<TripsNotifier, TripsUiState>(
  TripsNotifier.new,
);

class TripsNotifier extends Notifier<TripsUiState> {
  @override
  TripsUiState build() {
    unawaited(Future(() => load()));
    return const TripsUiState();
  }

  Future<void> load({bool forceRefresh = false}) async {
    if (state.bookings.isNotEmpty && !forceRefresh) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, error: '');
    try {
      final bookings = await ref
          .watch(bookingRepositoryProvider)
          .fetchBookings();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = TripsUiState(bookings: bookings);
    } catch (e, s) {
      AppLogger.error('Trips v2: load failed', e, s);
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load your inquiries. Pull to retry.',
      );
    }
  }

  Future<void> refresh() => load(forceRefresh: true);
}
