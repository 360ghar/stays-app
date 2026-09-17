import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/data/models/booking_model.dart';
import 'package:stays_app/app/data/repositories/booking_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

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
    if (!Get.isRegistered<BookingRepository>()) {
      state = state.copyWith(
        isLoading: false,
        error: 'Trips service unavailable.',
      );
      return;
    }
    try {
      final bookings = await Get.find<BookingRepository>().fetchBookings();
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
