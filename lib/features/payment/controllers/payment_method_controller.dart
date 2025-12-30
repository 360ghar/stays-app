import 'package:get/get.dart';

import 'package:stays_app/app/controllers/base/base_controller.dart';

class PaymentMethodController extends BaseController {
  final RxList<String> methods = <String>[].obs;
}
