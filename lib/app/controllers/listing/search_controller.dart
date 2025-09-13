import 'package:get/get.dart';

class SearchController extends GetxController {
  final RxString query = ''.obs;
  void onSearchChanged(String q) => query.value = q;
}
