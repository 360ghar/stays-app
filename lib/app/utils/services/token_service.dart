import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/interfaces/i_auth_repository.dart';
import '../../data/services/storage_service.dart';
import '../logger/app_logger.dart';

class TokenInfo {
  const TokenInfo({
    required this.accessToken,
    required this.createdAt,
    this.refreshToken,
    this.expiresAt,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final DateTime createdAt;

  bool get isExpired {
    final expAt = expiresAt;
    if (expAt == null) return false;
    final now = DateTime.now();
    const bufferTime = Duration(minutes: 5);
    return now.isAfter(expAt.subtract(bufferTime));
  }

  bool get shouldRefresh => isExpired;

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

}

class TokenService extends GetxService {
  TokenService({
    StorageService? storageService,
    IAuthRepository? authRepository,
  }) : _storageService = storageService,
       _authRepository = authRepository;

  static TokenService get I => Get.find<TokenService>();

  StorageService? _storageService;
  IAuthRepository? _authRepository;

  TokenInfo? _currentToken;
  Timer? _refreshTimer;
  final RxBool isAuthenticated = false.obs;
  final Completer<void> _ready = Completer<void>();
  bool _isRefreshing = false;
  bool _supabaseSessionAvailable = false;
  bool _initializationComplete = false;
  Object? _initializationError;

  /// Returns a Future that completes when initialization is done.
  /// Throws if initialization failed.
  Future<void> get ready async {
    await _ready.future;
    if (_initializationError != null) {
      throw _initializationError!;
    }
  }

  /// Returns true if initialization has completed successfully.
  /// Use this for synchronous checks when you need to know if the service is ready.
  bool get isReady => _initializationComplete && _initializationError == null;

  @override
  void onInit() {
    super.onInit();
    unawaited(_initialize());
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> storeTokens({
    required String accessToken,
    String? refreshToken,
    Duration? expiresIn,
  }) async {
    if (!_ready.isCompleted) {
      await ready;
    }
    try {
      final expiresAt = expiresIn != null
          ? DateTime.now().add(expiresIn)
          : null;

      _currentToken = TokenInfo(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      await _saveTokens();
      isAuthenticated.value = true;
      _startRefreshTimer();

      AppLogger.info('Tokens stored successfully');
    } catch (e) {
      AppLogger.error('Failed to store tokens', e);
      rethrow;
    }
  }

  String? get accessToken {
    // Safe access even before initialization
    if (!_initializationComplete) {
      // Try Supabase session as fallback before init completes
      try {
        final supabaseToken =
            Supabase.instance.client.auth.currentSession?.accessToken;
        if (supabaseToken != null) return supabaseToken;
      } catch (_) {
        // Supabase not ready yet
      }
      return null;
    }
    if (_supabaseSessionAvailable) {
      final supabaseToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      if (supabaseToken != null) return supabaseToken;
    }
    return _currentToken?.accessToken;
  }

  String? get refreshToken => _currentToken?.refreshToken;

  bool get hasValidToken {
    // Safe access even before initialization - check Supabase first
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.isExpired == false) {
        return true;
      }
    } catch (_) {
      // Supabase not ready yet
    }
    // If not initialized yet, don't trust in-memory token state
    if (!_initializationComplete) {
      return false;
    }
    if (_supabaseSessionAvailable) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.isExpired == false) {
        return true;
      }
    }
    return _currentToken != null && !_currentToken!.isExpired;
  }

  bool get needsRefresh {
    // If not initialized, can't determine refresh need from in-memory state
    if (!_initializationComplete) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null && session.isExpired == true) {
          return true;
        }
      } catch (_) {
        // Supabase not ready yet
      }
      return false;
    }
    if (_supabaseSessionAvailable) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.isExpired == true) {
        return true;
      }
    }
    return _currentToken?.shouldRefresh ?? false;
  }

  Future<bool> refreshIfNeeded() async {
    if (_supabaseSessionAvailable) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        if (session.isExpired == false) {
          return true;
        }
        final refreshed = await _refreshWithSupabase();
        if (refreshed) {
          return true;
        }
      }
    }

    if (_currentToken == null) {
      return false;
    }

    if (!_currentToken!.shouldRefresh) {
      return true;
    }

    return await _refreshTokens();
  }

  Future<void> clearTokens() async {
    if (!_ready.isCompleted) {
      await ready;
    }
    try {
      _currentToken = null;
      _supabaseSessionAvailable = false;
      await _storageService?.clearTokens();
      isAuthenticated.value = false;
      _stopRefreshTimer();

      AppLogger.info('Tokens cleared successfully');
    } catch (e) {
      AppLogger.error('Failed to clear tokens', e);
    }
  }

  bool validateTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      return parts.length == 3 && parts.every((part) => part.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic>? getTokenPayload(String? token) {
    if (!validateTokenFormat(token)) return null;

    try {
      final parts = token!.split('.');
      final payload = parts[1];

      String paddedPayload = payload;
      while (paddedPayload.length % 4 != 0) {
        paddedPayload += '=';
      }

      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      return jsonDecode(decodedPayload) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.warning('Failed to decode token payload: $e');
      return null;
    }
  }

  DateTime? get tokenExpiration => _currentToken?.expiresAt;

  Duration? get timeUntilExpiration {
    final expiration = _currentToken?.expiresAt;
    if (expiration == null) return null;

    return expiration.difference(DateTime.now());
  }

  Future<void> _initialize() async {
    try {
      if (_storageService == null) {
        await StorageService.ready;
        _storageService = Get.find<StorageService>();
      }

      if (_authRepository == null && Get.isRegistered<IAuthRepository>()) {
        _authRepository = Get.find<IAuthRepository>();
      }

      _checkSupabaseSession();
      await _loadStoredTokens();

      if (isAuthenticated.value) {
        _startRefreshTimer();
      }

      _initializationComplete = true;
    } catch (e, s) {
      AppLogger.error('TokenService initialization failed', e, s);
      _initializationError = e;
      _initializationComplete = false;
    } finally {
      if (!_ready.isCompleted) {
        _ready.complete();
      }
    }
  }

  void _checkSupabaseSession() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      _supabaseSessionAvailable = session != null;
      if (_supabaseSessionAvailable) {
        AppLogger.info('Supabase session detected');
      }
    } catch (e) {
      AppLogger.warning('Failed to check Supabase session: $e');
      _supabaseSessionAvailable = false;
    }
  }

  Future<void> _loadStoredTokens() async {
    try {
      if (_supabaseSessionAvailable) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null && session.isExpired == false) {
          isAuthenticated.value = true;
          AppLogger.info('Using Supabase session');
          return;
        }
      }

      final accessToken = await _storageService!.getAccessToken();
      final refreshToken = await _storageService!.getRefreshToken();
      final expiresAtStr = await _storageService!.getTokenExpiration();

      if (accessToken != null && accessToken.isNotEmpty) {
        _currentToken = TokenInfo(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAtStr != null
              ? DateTime.tryParse(expiresAtStr)
              : null,
          createdAt: DateTime.now(),
        );

        if (validateTokenFormat(_currentToken!.accessToken) &&
            !_currentToken!.isExpired) {
          isAuthenticated.value = true;
          AppLogger.info('Tokens loaded successfully from storage');
        } else {
          AppLogger.warning('Invalid or expired token in storage');
          await clearTokens();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load stored tokens', e);
      await clearTokens();
    }
  }

  Future<void> _saveTokens() async {
    if (_currentToken == null) return;
    if (!_ready.isCompleted) {
      await ready;
    }

    await _storageService!.saveTokens(
      accessToken: _currentToken!.accessToken,
      refreshToken: _currentToken!.refreshToken,
      expiresAt: _currentToken!.expiresAt?.toIso8601String(),
    );
  }

  Future<bool> _refreshWithSupabase() async {
    try {
      AppLogger.info('Refreshing Supabase session');
      final response = await Supabase.instance.client.auth.refreshSession();

      if (response.session != null) {
        _supabaseSessionAvailable = true;
        AppLogger.info('Supabase session refreshed successfully');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Supabase session refresh failed', e);
      _supabaseSessionAvailable = false;
      return false;
    }
  }

  Future<bool> _refreshTokens() async {
    if (_isRefreshing) {
      AppLogger.info('Token refresh already in progress, waiting...');
      await Future.delayed(const Duration(seconds: 1));
      return hasValidToken;
    }

    _isRefreshing = true;
    try {
      if (_currentToken?.refreshToken == null) {
        AppLogger.warning('No refresh token available');
        await clearTokens();
        return false;
      }

      if (_supabaseSessionAvailable) {
        final success = await _refreshWithSupabase();
        if (success) return true;
      }

      if (_authRepository != null) {
        AppLogger.info('Refreshing tokens via auth repository');
        final result = await _authRepository!.refreshTokens(
          _currentToken!.refreshToken!,
        );

        if (result.isSuccess && result.accessToken != null) {
          await storeTokens(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken,
          );
          AppLogger.info('Tokens refreshed successfully via repository');
          return true;
        }
      }

      AppLogger.warning('Token refresh failed - no valid auth provider');
      await clearTokens();
      return false;
    } catch (e) {
      AppLogger.error('Token refresh failed', e);
      await clearTokens();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _startRefreshTimer() {
    _stopRefreshTimer();

    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndRefreshTokens(),
    );
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> _checkAndRefreshTokens() async {
    if (needsRefresh) {
      await refreshIfNeeded();
    }
  }

  Future<bool> performTokenRefresh() async {
    return await _refreshTokens();
  }
}
