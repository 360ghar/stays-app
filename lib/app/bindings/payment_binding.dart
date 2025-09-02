import 'package:get/get.dart';

import '../controllers/payment/payment_controller.dart';
import '../controllers/payment/payment_method_controller.dart';
import '../data/providers/payment_provider.dart';
import '../data/repositories/payment_repository.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentProvider>(() => PaymentProvider());
    Get.lazyPut<PaymentRepository>(() => PaymentRepository(provider: Get.find<PaymentProvider>()));
    Get.lazyPut<PaymentController>(() => PaymentController());
    Get.lazyPut<PaymentMethodController>(() => PaymentMethodController());
  }
}

