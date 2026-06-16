import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Placeholder onboarding page for the stays app.
///
/// The stays app uses minimal onboarding — profile completion is the only
/// mandatory gate. This page marks onboarding as complete (persisted to the
/// backend so the gate advances past app_onboarding on the next launch) and
/// redirects to home. Replace with a real onboarding flow if needed.
class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  Future<void> _completeAndContinue() async {
    try {
      await Get.find<AuthRepository>().completeOnboarding(app: 'stays');
    } catch (e) {
      AppLogger.warning('Onboarding completion failed: $e');
    }
    Get.offAllNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Welcome to Stays',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all set!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _completeAndContinue,
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
