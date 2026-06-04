import 'package:get/get.dart';

import 'package:stays_app/features/payment/controllers/payment_controller.dart';
import 'package:stays_app/features/payment/controllers/payment_method_controller.dart';
import 'package:stays_app/app/data/providers/payment_provider.dart';
import 'package:stays_app/app/data/repositories/payment_repository.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentProvider>(() => PaymentProvider());
    Get.lazyPut<PaymentRepository>(
      () => PaymentRepository(provider: Get.find<PaymentProvider>()),
    );
    Get.lazyPut<PaymentController>(() => PaymentController());
    Get.lazyPut<PaymentMethodController>(() => PaymentMethodController());
  }
}
