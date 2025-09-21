import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/navigation_controller.dart';
import '../../views/home/simple_home_view.dart';

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    final tabIndex =
        args is Map<String, dynamic> ? args['tabIndex'] as int? : null;
    if (tabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<NavigationController>()) {
          Get.find<NavigationController>().changeTab(tabIndex);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SimpleHomeView();
  }
}
