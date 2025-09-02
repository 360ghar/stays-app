import 'package:flutter/material.dart';
import '../../../utils/constants/app_constants.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Let middleware handle redirection; just show splash
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
