import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';

class PaymentController extends BaseController {
  /// Indicates if a payment is being processed (distinct from general loading)
  final RxBool isProcessing = false.obs;
}
