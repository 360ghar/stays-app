import 'package:get/get.dart';

import '../controllers/enquiry/schedule_visit_controller.dart';
import '../data/providers/visit_provider.dart';
import '../data/repositories/visit_repository.dart';

class ScheduleVisitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitProvider>(() => VisitProvider());
    Get.lazyPut<VisitRepository>(
      () => VisitRepository(provider: Get.find<VisitProvider>()),
    );
    Get.lazyPut<ScheduleVisitController>(
      () => ScheduleVisitController(repository: Get.find<VisitRepository>()),
    );
  }
}
