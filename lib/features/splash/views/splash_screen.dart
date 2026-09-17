import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';

/// V2 splash. Logo beat, then session decides the landing page.
/// The router guard re-checks auth on every navigation regardless.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _proceed());
  }

  Future<void> _proceed() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    bool authed = false;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      authed = session != null && session.accessToken.isNotEmpty;
    } catch (_) {
      authed = false;
    }
    if (!mounted) return;
    context.go(authed ? AppPaths.explore : AppPaths.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: StayTokens.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 72,
              color: StayTokens.accentDark,
            ),
            SizedBox(height: StayTokens.s16),
            Text('360ghar stays', style: StayTokens.titleLarge),
            SizedBox(height: StayTokens.s8),
            Text(
              'Check in before you book in.',
              style: StayTokens.bodySecondary,
            ),
            SizedBox(height: StayTokens.s24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
