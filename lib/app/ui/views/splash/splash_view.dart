import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/app_constants.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_routes.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      // Wait for StorageService to be ready
      final storageService = await Get.putAsync<StorageService>(() async {
        final s = StorageService();
        await s.initialize();
        return s;
      });

      // Check if user is authenticated
      final token = await storageService.getAccessToken();
      
      // Add a small delay for better UX
      await Future.delayed(const Duration(seconds: 1));
      
      // Navigate based on auth status
      if (token != null) {
        Get.offAllNamed(Routes.home);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      // If something goes wrong, go to login
      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(AppConstants.appName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(AppConstants.tagLine),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
