import 'dart:async';

import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';
import 'package:stays_app/app/data/models/payment_model.dart';
import 'package:stays_app/app/data/repositories/payment_repository.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Manages the current user's saved payment methods via the backend.
class PaymentMethodController extends BaseController {
  PaymentMethodController({required PaymentRepository repository})
    : _repository = repository;

  final PaymentRepository _repository;
  final RxList<PaymentMethodModel> methods = <PaymentMethodModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadMethods());
  }

  Future<void> loadMethods() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _repository.listMethods();
      methods.assignAll(list);
    } catch (e, s) {
      AppLogger.error('Failed to load payment methods', e, s);
      errorMessage.value = 'Failed to load payment methods';
      methods.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addMethod({
    required String methodType,
    String? brand,
    String? last4,
    String? razorpayToken,
    String? razorpayPaymentId,
    String? nickname,
    bool isDefault = false,
  }) async {
    try {
      final method = await _repository.addMethod({
        'method_type': methodType,
        if (brand != null) 'brand': brand,
        if (last4 != null) 'last4': last4,
        if (razorpayToken != null) 'razorpay_token': razorpayToken,
        if (razorpayPaymentId != null) 'razorpay_payment_id': razorpayPaymentId,
        if (nickname != null) 'nickname': nickname,
        'is_default': isDefault,
      });
      methods.insert(0, method);
      if (isDefault) {
        // Server marked it default; clear flag on others locally for consistency.
        for (int i = 1; i < methods.length; i++) {
          methods[i] = PaymentMethodModel(
            id: methods[i].id,
            methodType: methods[i].methodType,
            brand: methods[i].brand,
            last4: methods[i].last4,
            nickname: methods[i].nickname,
            isDefault: false,
            createdAt: methods[i].createdAt,
          );
        }
      }
      AppSnackbar.success(
        title: 'Payment Method Added',
        message: '${method.displayName} saved.',
      );
    } catch (e, s) {
      AppLogger.error('Failed to add payment method', e, s);
      AppSnackbar.error(
        title: 'Error',
        message: 'Failed to add payment method. Please try again.',
      );
    }
  }

  Future<void> removeMethod(int methodId) async {
    final index = methods.indexWhere((m) => m.id == methodId);
    final removed = index != -1 ? methods[index] : null;
    if (index != -1) methods.removeAt(index);
    try {
      await _repository.removeMethod(methodId);
      AppSnackbar.success(title: 'Removed', message: 'Payment method removed.');
    } catch (e, s) {
      AppLogger.error('Failed to remove payment method', e, s);
      if (removed != null) methods.insert(index, removed);
      AppSnackbar.error(
        title: 'Error',
        message: 'Failed to remove payment method. Please try again.',
      );
    }
  }
}
