import 'dart:convert';
import 'dart:async';

import 'package:get/get.dart';

import '../../data/services/storage_service.dart';
import '../logger/app_logger.dart';

/// Token information with expiration tracking
class TokenInfo {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const TokenInfo({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    required this.createdAt,
  });

  /// Check if the access token is expired or will expire within the buffer time
  bool get isExpired {
    if (expiresAt == null) return false;
    final now = DateTime.now();
    final bufferTime = Duration(minutes: 5); // 5-minute buffer
    return now.isAfter(expiresAt!.subtract(bufferTime));
  }

  /// Check if the token should be refreshed
  bool get shouldRefresh => isExpired;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
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
}

/// Secure token management service with automatic refresh
class TokenService extends GetxService {
  static TokenService get I => Get.find<TokenService>();

  StorageService? _storageService;

  TokenInfo? _currentToken;
  Timer? _refreshTimer;
  final RxBool isAuthenticated = false.obs;
  final Completer<void> _ready = Completer<void>();

  /// Future that completes once tokens have been loaded from storage
  Future<void> get ready => _ready.future;

  TokenService({StorageService? storageService}) {
    if (storageService != null) {
      _storageService = storageService;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  /// Store tokens securely
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

      AppLogger.info('Tokens stored successfully');
    } catch (e) {
      AppLogger.error('Failed to store tokens', e);
      rethrow;
    }
  }

  /// Get current access token
  String? get accessToken => _currentToken?.accessToken;

  /// Get current refresh token
  String? get refreshToken => _currentToken?.refreshToken;

  /// Check if user is authenticated
  bool get hasValidToken => _currentToken != null && !_currentToken!.isExpired;

  /// Check if token needs refresh
  bool get needsRefresh => _currentToken?.shouldRefresh ?? false;

  /// Refresh tokens if needed
  Future<bool> refreshIfNeeded() async {
    if (_currentToken == null) {
      return false;
    }
    if (!_currentToken!.shouldRefresh) {
      return true;
    }
    return await _refreshTokens();
  }

  /// Clear all stored tokens
  Future<void> clearTokens() async {
    if (!_ready.isCompleted) {
      await ready;
    }
    try {
      _currentToken = null;
      await _storageService!.clearTokens();
      isAuthenticated.value = false;
      _stopRefreshTimer();

      AppLogger.info('Tokens cleared successfully');
    } catch (e) {
      AppLogger.error('Failed to clear tokens', e);
    }
  }

  /// Validate current token format
  bool validateTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;

    try {
      // Basic JWT format validation (header.payload.signature)
      final parts = token.split('.');
      return parts.length == 3 && parts.every((part) => part.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  /// Extract token payload (for debugging only, not for security decisions)
  Map<String, dynamic>? getTokenPayload(String? token) {
    if (!validateTokenFormat(token)) return null;

    try {
      final parts = token!.split('.');
      final payload = parts[1];

      // Pad base64 string if needed
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

  /// Get token expiration time
  DateTime? get tokenExpiration => _currentToken?.expiresAt;

  /// Get time until token expiration
  Duration? get timeUntilExpiration {
    final expiration = _currentToken?.expiresAt;
    if (expiration == null) return null;

    return expiration.difference(DateTime.now());
  }

  Future<void> _initialize() async {
    try {
      // Resolve StorageService if not injected
      if (_storageService == null) {
        await StorageService.ready;
        _storageService = Get.find<StorageService>();
      }

      await _loadStoredTokens();
      // TODO: Enable timer after implementing _refreshTokens()
      // _startRefreshTimer();
    } finally {
      if (!_ready.isCompleted) {
        _ready.complete();
      }
    }
  }

  /// Load stored tokens from secure storage
  Future<void> _loadStoredTokens() async {
    try {
      final accessToken = await _storageService!.getAccessToken();
      final refreshToken = await _storageService!.getRefreshToken();
      final expiresAtStr = await _storageService!.getTokenExpiration();

      if (accessToken != null && accessToken.isNotEmpty) {
        _currentToken = TokenInfo(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null,
          createdAt: DateTime.now(),
        );

        // Validate token format
        if (validateTokenFormat(_currentToken!.accessToken) && !_currentToken!.isExpired) {
          isAuthenticated.value = true;
          AppLogger.info('Tokens loaded successfully');
        } else {
          AppLogger.warning('Invalid token format in storage');
          await clearTokens();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load stored tokens', e);
      await clearTokens();
    }
  }

  /// Save tokens to secure storage
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

  /// Refresh tokens (placeholder - implement with your auth provider)
  Future<bool> _refreshTokens() async {
    if (_currentToken?.refreshToken == null) {
      AppLogger.warning('No refresh token available');
      await clearTokens();
      return false;
    }

    try {
      // This should be implemented with your actual auth provider
      // For now, this is a placeholder
      AppLogger.info('Token refresh needed - implement with auth provider');

      // Example implementation would be:
      // final authRepository = Get.find<IAuthRepository>();
      // final result = await authRepository.refreshTokens(_currentToken!.refreshToken!);
      // if (result.isSuccess) {
      //   await storeTokens(
      //     accessToken: result.accessToken!,
      //     refreshToken: result.refreshToken,
      //   );
      //   return true;
      // }

      return false;
    } catch (e) {
      AppLogger.error('Token refresh failed', e);
      await clearTokens();
      return false;
    }
  }

  /// Start automatic refresh timer
  void _startRefreshTimer() {
    _stopRefreshTimer();

    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndRefreshTokens(),
    );
  }

  /// Stop refresh timer
  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Check and refresh tokens periodically
  Future<void> _checkAndRefreshTokens() async {
    if (needsRefresh) {
      await refreshIfNeeded();
    }
  }

  /// Manual token refresh for immediate needs
  Future<bool> performTokenRefresh() async {
    return await _refreshTokens();
  }
}
