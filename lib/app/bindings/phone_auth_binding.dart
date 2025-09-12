import 'package:get/get.dart';
import '../controllers/auth/phone_auth_controller.dart';
import '../data/services/storage_service.dart';

class PhoneAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PhoneAuthController>(
      () => PhoneAuthController(
        storageService: Get.find<StorageService>(),
      ),
    );
  }
}