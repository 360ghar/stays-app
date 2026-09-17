import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/data/models/payment_model.dart';
import 'package:stays_app/app/data/repositories/payment_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

class PaymentMethodsUiState {
  const PaymentMethodsUiState({
    this.methods = const [],
    this.isLoading = true,
    this.error = '',
  });
  final List<PaymentMethodModel> methods;
  final bool isLoading;
  final String error;

  PaymentMethodsUiState copyWith({
    List<PaymentMethodModel>? methods,
    bool? isLoading,
    String? error,
  }) {
    return PaymentMethodsUiState(
      methods: methods ?? this.methods,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final paymentMethodsProvider =
    NotifierProvider<PaymentMethodsNotifier, PaymentMethodsUiState>(
      PaymentMethodsNotifier.new,
    );

class PaymentMethodsNotifier extends Notifier<PaymentMethodsUiState> {
  @override
  PaymentMethodsUiState build() {
    unawaited(Future(() => load()));
    return const PaymentMethodsUiState();
  }

  PaymentRepository? get _repo => Get.isRegistered<PaymentRepository>()
      ? Get.find<PaymentRepository>()
      : null;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: '');
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'Payment service unavailable.',
      );
      return;
    }
    try {
      final list = await repo.listMethods();
      state = PaymentMethodsUiState(methods: list);
    } catch (e, s) {
      AppLogger.error('Payment methods v2: load failed', e, s);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payment methods.',
        methods: const [],
      );
    }
  }

  Future<void> refresh() => load();

  Future<void> remove(int methodId) async {
    final index = state.methods.indexWhere((m) => m.id == methodId);
    final removed = index != -1 ? state.methods[index] : null;
    if (index != -1) {
      final next = [...state.methods]..removeAt(index);
      state = state.copyWith(methods: next);
    }
    try {
      await _repo?.removeMethod(methodId);
    } catch (e, s) {
      AppLogger.error('Payment methods v2: remove failed', e, s);
      if (removed != null) {
        final next = [...state.methods];
        next.insert(index.clamp(0, next.length), removed);
        state = state.copyWith(methods: next);
      }
    }
  }
}
