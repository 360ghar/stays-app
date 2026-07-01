import 'dart:async';

import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/payment_model.dart';
import 'package:stays_app/app/data/repositories/payment_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Integrates Razorpay checkout with the backend order + verify endpoints.
class PaymentController extends BaseController {
  PaymentController({required PaymentRepository repository})
    : _repository = repository;

  final PaymentRepository _repository;
  Razorpay? _razorpay;

  /// Indicates if a payment is being processed (distinct from general loading)
  final RxBool isProcessing = false.obs;
  final Rxn<RazorpayOrderModel> activeOrder = Rxn<RazorpayOrderModel>();
  final RxInt bookingId = 0.obs;
  final RxDouble amount = 0.0.obs;
  final RxString currency = 'INR'.obs;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    _razorpay?.clear();
    _razorpay = null;
    super.onClose();
  }

  /// Configure the booking to pay for. Call before [processPayment].
  void configure({
    required int bookingId,
    required double amount,
    String currency = 'INR',
  }) {
    this.bookingId.value = bookingId;
    this.amount.value = amount;
    this.currency.value = currency;
  }

  /// Kicks off the full flow: create order -> open checkout -> verify.
  Future<void> processPayment({
    String? name,
    String? email,
    String? phone,
  }) async {
    if (isProcessing.value) return;
    if (bookingId.value <= 0) {
      AppSnackbar.warning(
        title: 'Payment',
        message: 'No booking selected for payment.',
      );
      return;
    }

    isProcessing.value = true;
    isLoading.value = true;
    try {
      final order = await _repository.createRazorpayOrder(bookingId.value);
      activeOrder.value = order;
      AppLogger.info('Razorpay order created: ${order.orderId}');

      if (order.keyId == null || order.keyId!.isEmpty) {
        AppSnackbar.error(
          title: 'Payment Failed',
          message: 'Payment configuration error. Please contact support.',
        );
        isProcessing.value = false;
        return;
      }

      final options = <String, dynamic>{
        'key': order.keyId,
        'order_id': order.orderId,
        // Backend returns amount in rupees; Razorpay expects paise.
        'amount': (order.amount * 100).round(),
        'currency': order.currency,
        'name': name ?? '360ghar Stays',
        'prefill': <String, dynamic>{
          if (email != null && email.isNotEmpty) 'email': email,
          if (phone != null && phone.isNotEmpty) 'contact': phone,
        },
        'notes': order.notes,
      };
      // isProcessing stays true until the Razorpay callbacks fire
      // (_handleSuccess / _handleError reset it).
      _razorpay?.open(options);
    } catch (e, s) {
      AppLogger.error('Failed to start Razorpay payment', e, s);
      AppSnackbar.error(
        title: 'Payment Failed',
        message: 'Unable to start payment. Please try again.',
      );
      // Order creation or checkout open failed — reset so the user can retry.
      isProcessing.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    AppLogger.info(
      'Razorpay payment success: ${response.paymentId} order ${response.orderId}',
    );
    try {
      final ok = await _repository.verifyRazorpayPayment(
        bookingId: bookingId.value,
        razorpayOrderId: response.orderId ?? activeOrder.value?.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      if (ok) {
        AppSnackbar.success(
          title: 'Payment Successful',
          message: 'Your booking has been confirmed.',
        );
        unawaited(Get.offAllNamed(Routes.home, arguments: 1));
      } else {
        AppSnackbar.error(
          title: 'Verification Failed',
          message: 'Payment could not be verified. Contact support.',
        );
      }
    } catch (e, s) {
      AppLogger.error('Razorpay verification failed', e, s);
      AppSnackbar.error(
        title: 'Verification Failed',
        message: 'Payment could not be verified. Contact support.',
      );
    } finally {
      isProcessing.value = false;
    }
  }

  void _handleError(PaymentFailureResponse response) {
    AppLogger.warning(
      'Razorpay payment error: code=${response.code} message=${response.message}',
    );
    isProcessing.value = false;
    if (response.code == 2) {
      // User cancelled
      AppSnackbar.info(
        title: 'Payment Cancelled',
        message: 'You cancelled the payment.',
      );
      return;
    }
    AppSnackbar.error(
      title: 'Payment Failed',
      message: response.message ?? 'Payment failed. Please try again.',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.info('Razorpay external wallet: ${response.walletName}');
    AppSnackbar.info(
      title: 'Wallet',
      message: 'External wallet ${response.walletName ?? ''} selected.',
    );
  }
}
