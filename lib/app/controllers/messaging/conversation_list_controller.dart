import 'package:get/get.dart';

class ConversationListController extends GetxController {
  final RxList<String> conversations = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Seed some sample data for UI preview
    conversations.assignAll([
      'Booking #A1 · Host Alice',
      'Inquiry · Cozy loft',
      'Re: Check-in time',
    ]);
  }
}
