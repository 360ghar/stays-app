import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/features/splash/controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/360Stays_logo.png',
              width: 200,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
