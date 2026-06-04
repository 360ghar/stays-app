import 'package:get/get.dart';

import 'package:stays_app/features/update/controllers/force_update_controller.dart';

/// Binding for the force update screen.
class ForceUpdateBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ForceUpdateController>(ForceUpdateController());
  }
}
