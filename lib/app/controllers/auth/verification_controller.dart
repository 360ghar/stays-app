import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class VerificationController extends GetxController {
  final RxBool isVerifying = false.obs;
  Future<void> verifyEmail(String token) async {
    isVerifying.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    Get.snackbar('Verified', 'Your email has been verified');
    Get.offAllNamed(Routes.login);
    isVerifying.value = false;
  }
}
