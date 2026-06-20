import 'package:get/get.dart';

import 'package:stays_app/app/data/providers/review_provider.dart';
import 'package:stays_app/app/data/repositories/review_repository.dart';

class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewProvider>(() => ReviewProvider());
    Get.lazyPut<ReviewRepository>(
      () => ReviewRepository(provider: Get.find<ReviewProvider>()),
    );
  }
}
