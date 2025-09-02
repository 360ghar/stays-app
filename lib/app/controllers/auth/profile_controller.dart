import 'package:get/get.dart';

import '../../data/models/user_model.dart';

class ProfileController extends GetxController {
  final Rx<UserModel?> profile = Rx<UserModel?>(null);
}

