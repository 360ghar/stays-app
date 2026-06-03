import 'package:get/get.dart';
import 'package:stays_app/app/controllers/base/base_controller.dart';

class ChatController extends BaseController {
  final RxList<String> messages = <String>[].obs;
}
