import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/features/auth/providers/auth_providers.dart';

/// V2 login. Identifier + password, Google, Apple (iOS). Success → explore.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  void _goExplore(bool ok) {
    if (!ok || !mounted) return;
    // Resume the pre-login target (deep link / notification tap).
    // Only internal paths are honored to block open redirects.
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    if (from != null && from.startsWith('/') && !from.startsWith('//')) {
      context.go(from);
      return;
    }
    context.go(AppPaths.explore);
  }

  void _submitLogin() {
    ref
        .read(authProvider.notifier)
        .login(identifier: _identifier.text, password: _password.text)
        .then(_goExplore)
        .ignore();
  }

  void _submitGoogle() {
    ref.read(authProvider.notifier).loginWithGoogle().then(_goExplore).ignore();
  }

  void _submitApple() {
    ref.read(authProvider.notifier).loginWithApple().then(_goExplore).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final busy = state.status == AuthStatus.busy;
    return Scaffold(
      backgroundColor: StayTokens.paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(StayTokens.s24),
          children: [
            const SizedBox(height: StayTokens.s32),
            const Icon(
              Icons.home_work_outlined,
              size: 56,
              color: StayTokens.accentDark,
            ),
            const SizedBox(height: StayTokens.s16),
            const Text(
              'Check in before you book in.',
              style: StayTokens.titleLarge,
            ),
            const Text(
              '360° tours of every stay.',
              style: StayTokens.bodySecondary,
            ),
            const SizedBox(height: StayTokens.s32),
            TextField(
              controller: _identifier,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email or phone',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: StayTokens.s12),
            TextField(
              controller: _password,
              obscureText: _obscured,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitLogin(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscured ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
            ),
            if (state.error.isNotEmpty) ...[
              const SizedBox(height: StayTokens.s12),
              Text(
                state.error,
                style: StayTokens.body.copyWith(color: StayTokens.danger),
              ),
            ],
            const SizedBox(height: StayTokens.s16),
            FilledButton(
              onPressed: busy ? null : _submitLogin,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Log in'),
            ),
            const SizedBox(height: StayTokens.s16),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: StayTokens.s12),
                  child: Text('or', style: StayTokens.label),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: StayTokens.s16),
            OutlinedButton.icon(
              onPressed: busy ? null : _submitGoogle,
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Continue with Google'),
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: StayTokens.s12),
              OutlinedButton.icon(
                onPressed: busy ? null : _submitApple,
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
