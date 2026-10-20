import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/utils/exceptions/app_exceptions.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'package:stays_app/core/providers/data_providers.dart';

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

  AuthRepository get _repo => ref.watch(authRepositoryProvider);

  Future<bool> _run(Future<UserModel?> Function() action) async {
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
      return _run(() => _repo.loginWithEmail(email: id, password: password));
    }
    return _run(() => _repo.loginWithPhone(phone: id, password: password));
  }

  Future<bool> loginWithGoogle() {
    return _run(() async {
      final result = await _repo.signInWithGoogle();
      return result.user;
    });
  }

  Future<bool> loginWithApple() {
    return _run(() => _repo.signInWithApple());
  }

  Future<void> logout() async {
    // The unregister route needs the session, so it runs before the sign-out.
    await ref.read(pushNotificationServiceProvider).unregisterDevice();
    await _endSession();
  }

  /// Deletes the account on the backend (`DELETE /api/v1/users/me`), then ends
  /// the local session. Returns false, with [AuthUiState.error] set, when the
  /// backend refuses. The session is kept in that case.
  Future<bool> deleteAccount() async {
    state = state.copyWith(status: AuthStatus.busy, error: '');
    try {
      await ref.read(pushNotificationServiceProvider).unregisterDevice();
      await _repo.deleteAccount();
    } catch (e, s) {
      AppLogger.error('Auth v2: delete account failed', e, s);
      state = state.copyWith(
        status: AuthStatus.error,
        error: e is ApiException && e.message.trim().isNotEmpty
            ? e.message
            : 'Could not delete your account. Please try again.',
      );
      return false;
    }
    await _endSession();
    return true;
  }

  Future<void> _endSession() async {
    try {
      await _repo.logout();
    } catch (e, s) {
      AppLogger.error('Auth v2: logout failed', e, s);
    }
    state = const AuthUiState();
  }
}
