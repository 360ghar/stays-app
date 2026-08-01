import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

/// Real onboarding flow for the stays app.
///
/// A multi-page walkthrough that introduces the value proposition before
/// calling [AuthRepository.completeOnboarding] and routing to /home.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pageController = PageController();
  final _currentPage = 0.obs;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.travel_explore,
      title: 'Discover your next stay',
      body: 'Browse hotels, homestays, and Airbnbs curated for every trip.',
    ),
    _OnboardingSlide(
      icon: Icons.threesixty,
      title: 'Explore in 360°',
      body: 'Take a virtual tour and feel at home before you book.',
    ),
    _OnboardingSlide(
      icon: Icons.chat_bubble_outline,
      title: 'Book with confidence',
      body:
          'Send inquiries, chat with hosts, and manage your trips in one place.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) => _currentPage.value = index;

  Future<void> _completeAndContinue() async {
    try {
      await Get.find<AuthRepository>().completeOnboarding();
    } catch (e) {
      AppLogger.warning('Onboarding completion failed: $e');
    }
    await Get.offAllNamed(Routes.home);
  }

  void _nextPage() {
    final next = _currentPage.value + 1;
    if (next < _slides.length) {
      unawaited(
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    } else {
      unawaited(_completeAndContinue());
    }
  }

  void _skipToEnd() => _pageController.jumpToPage(_slides.length - 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Obx(
                () => _currentPage.value < _slides.length - 1
                    ? TextButton(
                        onPressed: _skipToEnd,
                        child: const Text('Skip'),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) =>
                    _buildSlide(context, _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() => _buildDots(context)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => FilledButton(
                        onPressed: _nextPage,
                        child: Text(
                          _currentPage.value == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(BuildContext context, _OnboardingSlide slide) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: colors.primaryContainer,
            child: Icon(slide.icon, size: 56, color: colors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDots(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage.value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : colors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
