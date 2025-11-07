import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../services/storage_service.dart';
import 'auth/i_auth_provider.dart';
import '../../utils/logger/app_logger.dart';

class SupabaseAuthProvider extends GetxService implements IAuthProvider {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  final StorageService _storage = Get.find<StorageService>();

  @override
  Future<ProviderAuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _syncTokens(res.session);
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<ProviderAuthResult> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      phone: _ensureE164(phone),
      password: password,
    );
    await _syncTokens(res.session);
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<ProviderAuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    await _syncTokens(res.session);
    return ProviderAuthResult(
      accessToken: res.session?.accessToken,
      refreshToken: res.session?.refreshToken,
      rawUser: _mapUser(res.user),
    );
  }

  @override
  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    final res = await _supabase.auth.signUp(
      phone: _ensureE164(phone),
      password: password,
    );
    AppLogger.info('Supabase phone signUp: user=${res.user?.id}');
    return true;
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  }) async {
    await _supabase.auth.updateUser(
      supabase.UserAttributes(password: newPassword),
    );
    if (currentPassword != null && currentPassword.isNotEmpty) {
      final email = _supabase.auth.currentUser?.email;
      if (email != null) {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: newPassword,
        );
      }
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } finally {
      await _storage.clearTokens();
      await _storage.clearUserData();
    }
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserRaw() async {
    final u = _supabase.auth.currentUser;
    return _mapUser(u);
  }

  @override
  Future<bool> isAuthenticated() async {
    final session = _supabase.auth.currentSession;
    return session != null && session.accessToken.isNotEmpty;
  }

  Future<void> _syncTokens(supabase.Session? session) async {
    if (session == null) return;
    await _storage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
  }

  Map<String, dynamic>? _mapUser(supabase.User? user) {
    if (user == null) return null;
    final meta = user.userMetadata ?? {};
    return {
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'first_name': meta['first_name'],
      'last_name': meta['last_name'],
      'full_name': meta['full_name'] ?? meta['name'],
    };
  }

  String _ensureE164(String phone) {
    final trimmed = phone.replaceAll(RegExp(r'\s+'), '');
    if (trimmed.startsWith('+')) return trimmed;
    return '+91$trimmed';
  }
}

