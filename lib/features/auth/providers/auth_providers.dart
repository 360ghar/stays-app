import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;

import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';

enum AuthStatus { idle, busy, error }

class AuthUiState {
  const AuthUiState({
    this.status = AuthStatus.idle,
    this.error = '',
    this.user,
  });
  final AuthStatus status;
  final String error;
  final UserModel? user;

  AuthUiState copyWith({AuthStatus? status, String? error, UserModel? user}) {
    return AuthUiState(
      status: status ?? this.status,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }
}

/// V2 auth. Delegates to the canonical [AuthRepository] (no navigation
/// side effects); v2 screens navigate via go_router on success.
final authProvider = NotifierProvider<AuthNotifier, AuthUiState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState();

  AuthRepository? get _repo =>
      Get.isRegistered<AuthRepository>() ? Get.find<AuthRepository>() : null;

  Future<bool> _run(Future<UserModel?> Function() action) async {
    final repo = _repo;
    if (repo == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Auth service unavailable.',
      );
      return false;
    }
    state = state.copyWith(status: AuthStatus.busy, error: '');
    try {
      final user = await action();
      if (user == null) {
        state = state.copyWith(
          status: AuthStatus.error,
          error: 'Could not sign you in. Please try again.',
        );
        return false;
      }
      state = AuthUiState(user: user);
      return true;
    } catch (e, s) {
      AppLogger.error('Auth v2 failed', e, s);
      state = state.copyWith(
        status: AuthStatus.error,
        error: 'Could not sign you in. Check your details and try again.',
      );
      return false;
    }
  }

  Future<bool> login({required String identifier, required String password}) {
    final id = identifier.trim();
    if (id.contains('@')) {
      return _run(() => _repo!.loginWithEmail(email: id, password: password));
    }
    return _run(() => _repo!.loginWithPhone(phone: id, password: password));
  }

  Future<bool> loginWithGoogle() {
    return _run(() async {
      final result = await _repo!.signInWithGoogle();
      return result.user;
    });
  }

  Future<bool> loginWithApple() {
    return _run(() => _repo!.signInWithApple());
  }

  Future<void> logout() async {
    try {
      await _repo?.logout();
    } catch (e, s) {
      AppLogger.error('Auth v2: logout failed', e, s);
    }
    state = const AuthUiState();
  }
}
