import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:get/get.dart';

import '../../../bindings/home_binding.dart';
import '../../../bindings/message_binding.dart';
import '../../../bindings/profile_binding.dart';
import '../../views/home/simple_home_view.dart';
import '../../views/booking/trips_view.dart';
import '../../views/messaging/inbox_view.dart';
import '../../views/profile/profile_view.dart';

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Ensure required bindings are ready for tabs
    HomeBinding().dependencies();
    MessageBinding().dependencies();
    ProfileBinding().dependencies();
  }

  @override
  Widget build(BuildContext context) {
    return const SimpleHomeView();
  }
}
