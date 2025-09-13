import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../../utils/logger/app_logger.dart';
import '../../utils/exceptions/app_exceptions.dart';

class AuthRepository {
  // Supabase client handles auth, session persistence, refresh
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  final StorageService _storage = Get.find<StorageService>();

  AuthRepository();

  // Email + password sign-in (kept for backward compatibility)
  Future<UserModel> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = res.session;
      final user = res.user;
      if (user == null) {
        throw ApiException(message: 'Invalid credentials', statusCode: 401);
      }
      // Optionally sync tokens for legacy consumers
      await _syncTokensFromSession(session);
      final mapped = _mapUser(user);
      await _persistUserData(mapped);
      return mapped;
    } on supabase.AuthException catch (e) {
      throw ApiException(message: e.message, statusCode: 401);
    }
  }

  // Phone + password sign-in
  Future<UserModel> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final formatted = _ensureE164(phone);
      final res = await _supabase.auth.signInWithPassword(
        phone: formatted,
        password: password,
      );
      final session = res.session;
      final user = res.user;
      if (user == null) {
        throw ApiException(message: 'Invalid credentials', statusCode: 401);
      }
      await _syncTokensFromSession(session);
      final mapped = _mapUser(user);
      await _persistUserData(mapped);
      return mapped;
    } on supabase.AuthException catch (e) {
      throw ApiException(message: e.message, statusCode: 401);
    }
  }

  // Email signup (optional)
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      final user = res.user;
      if (user == null) {
        throw ApiException(
          message:
              'Registration requires verification. Please check your email.',
          statusCode: 202,
        );
      }
      final mapped = _mapUser(user);
      await _persistUserData(mapped);
      await _syncTokensFromSession(res.session);
      return mapped;
    } on supabase.AuthException catch (e) {
      throw ApiException(message: e.message, statusCode: 400);
    }
  }

  // Phone signup -> triggers SMS OTP. Returns true if OTP sent.
  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final formatted = _ensureE164(phone);
      final res = await _supabase.auth.signUp(
        phone: formatted,
        password: password,
      );
      // For phone sign-up, session is usually null until OTP verified
      AppLogger.info(
        'SignUp (phone) response: user=${res.user?.id}, session=${res.session != null}',
      );
      return true;
    } on supabase.AuthException catch (e) {
      // If already registered, surface a helpful message
      throw ApiException(message: e.message, statusCode: 400);
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } finally {
      await _storage.clearTokens();
      await _storage.clearUserData();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final u = _supabase.auth.currentUser;
    if (u != null) {
      final mapped = _mapUser(u);
      await _persistUserData(mapped);
      return mapped;
    }
    // Fallback to cached user data if session not present
    final userData = await _storage.getUserData();
    if (userData != null) {
      return UserModel.fromMap(userData);
    }
    return null;
  }

  Future<bool> isAuthenticated() async {
    final session = _supabase.auth.currentSession;
    return session != null && session.accessToken.isNotEmpty;
  }

  // Helpers
  UserModel _mapUser(supabase.User user) {
    final meta = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      email: user.email,
      phone: user.phone,
      firstName: meta['first_name'] as String?,
      lastName: meta['last_name'] as String?,
      name: (meta['full_name'] as String?) ?? (meta['name'] as String?),
    );
  }

  String _ensureE164(String phone) {
    final trimmed = phone.replaceAll(RegExp(r'\s+'), '');
    if (trimmed.startsWith('+')) return trimmed;
    // Default to India code if not provided
    return '+91$trimmed';
  }

  Future<void> _syncTokensFromSession(supabase.Session? session) async {
    if (session == null) return;
    try {
      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    } catch (e) {
      AppLogger.warning('Failed to sync tokens to legacy storage: $e');
    }
  }

  Future<void> _persistUserData(UserModel user) async {
    await _storage.saveUserData(user.toMap());
  }
}
