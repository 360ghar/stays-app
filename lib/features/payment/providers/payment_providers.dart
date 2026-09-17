import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:stays_app/app/data/models/payment_model.dart';
import 'package:stays_app/app/data/repositories/payment_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

enum PaymentStatus { idle, processing, success, failed, cancelled }

class PaymentUiState {
  const PaymentUiState({
    this.bookingId = 0,
    this.amount = 0,
    this.currency = 'INR',
    this.status = PaymentStatus.idle,
    this.message = '',
  });
  final int bookingId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String message;

  PaymentUiState copyWith({
    int? bookingId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? message,
  }) {
    return PaymentUiState(
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

final paymentProvider = NotifierProvider<PaymentNotifier, PaymentUiState>(
  PaymentNotifier.new,
);

class PaymentNotifier extends Notifier<PaymentUiState> {
  Razorpay? _razorpay;
  RazorpayOrderModel? _activeOrder;

  @override
  PaymentUiState build() {
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    ref.onDispose(() {
      _razorpay?.clear();
      _razorpay = null;
    });
    return const PaymentUiState();
  }

  PaymentRepository? get _repo => Get.isRegistered<PaymentRepository>()
      ? Get.find<PaymentRepository>()
      : null;

  void configure({
    required int bookingId,
    required double amount,
    String currency = 'INR',
  }) {
    state = state.copyWith(
      bookingId: bookingId,
      amount: amount,
      currency: currency,
      status: PaymentStatus.idle,
      message: '',
    );
  }

  Future<void> process({String? name, String? email, String? phone}) async {
    final repo = _repo;
    if (state.status == PaymentStatus.processing) return;
    if (state.bookingId <= 0) {
      state = state.copyWith(
        status: PaymentStatus.failed,
        message: 'No booking selected for payment.',
      );
      return;
    }
    if (repo == null) {
      state = state.copyWith(
        status: PaymentStatus.failed,
        message: 'Payment service unavailable.',
      );
      return;
    }
    state = state.copyWith(status: PaymentStatus.processing, message: '');
    try {
      final order = await repo.createRazorpayOrder(state.bookingId);
      _activeOrder = order;
      AppLogger.info('Razorpay order created: ${order.orderId}');
      if (order.keyId == null || order.keyId!.isEmpty) {
        state = state.copyWith(
          status: PaymentStatus.failed,
          message: 'Payment configuration error. Please contact support.',
        );
        return;
      }
      // Razorpay checkout options contract (Map<String, dynamic>, wire
      // format frozen — comments only, keys/values unchanged):
      // - `key` (String): Razorpay key id from the created order.
      // - `order_id` (String): server-created order id under verification.
      // - `amount` (int): minor units (paise) = order.amount * 100.
      // - `currency` (String): e.g. 'INR'.
      // - `name` (String): merchant display name.
      // - `prefill` (Map): optional `email` + `contact` (phone) when known.
      // - `notes` (Map?): passthrough order notes from the backend.
      _razorpay?.open({
        'key': order.keyId, // String
        'order_id': order.orderId, // String
        'amount': (order.amount * 100).round(), // int (paise)
        'currency': order.currency, // String
        'name': name ?? '360ghar Stays', // String
        'prefill': <String, dynamic>{
          if (email != null && email.isNotEmpty) 'email': email, // String?
          if (phone != null && phone.isNotEmpty) 'contact': phone, // String?
        },
        'notes': order.notes, // Map? passthrough
      });
    } catch (e, s) {
      AppLogger.error('Payment v2: order creation failed', e, s);
      state = state.copyWith(
        status: PaymentStatus.failed,
        message: 'Unable to start payment. Please try again.',
      );
    }
  }

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    final repo = _repo;
    AppLogger.info('Razorpay payment success: ${response.paymentId}');
    if (repo == null) {
      state = state.copyWith(
        status: PaymentStatus.failed,
        message: 'Payment could not be verified. Contact support.',
      );
      return;
    }
    try {
      final ok = await repo.verifyRazorpayPayment(
        bookingId: state.bookingId,
        razorpayOrderId: response.orderId ?? _activeOrder?.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      state = state.copyWith(
        status: ok ? PaymentStatus.success : PaymentStatus.failed,
        message: ok
            ? 'Payment successful. Booking confirmed.'
            : 'Payment could not be verified. Contact support.',
      );
    } catch (e, s) {
      AppLogger.error('Payment v2: verification failed', e, s);
      state = state.copyWith(
        status: PaymentStatus.failed,
        message: 'Payment could not be verified. Contact support.',
      );
    }
  }

  void _handleError(PaymentFailureResponse response) {
    AppLogger.warning('Razorpay payment error: code=${response.code}');
    if (response.code == 2) {
      state = state.copyWith(
        status: PaymentStatus.cancelled,
        message: 'You cancelled the payment.',
      );
      return;
    }
    state = state.copyWith(
      status: PaymentStatus.failed,
      message: response.message ?? 'Payment failed. Please try again.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.info('Razorpay external wallet: ${response.walletName}');
  }
}
