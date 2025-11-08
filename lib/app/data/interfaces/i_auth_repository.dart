import '../models/user_model.dart';

/// Authentication result containing user data and tokens
class AuthResult {
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final String? error;

  const AuthResult._({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.error,
  });

  factory AuthResult.success({
    required UserModel user,
    required String accessToken,
    String? refreshToken,
  }) {
    return AuthResult._(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
      error: null,
    );
  }

  factory AuthResult.failure({
    required String error,
  }) {
    return AuthResult._(
      user: null,
      accessToken: null,
      refreshToken: null,
      error: error,
    );
  }

  bool get isSuccess => error == null && user != null && accessToken != null;
  bool get isFailure => error != null;
  bool get isUnknown => !isSuccess && !isFailure;
}

/// User registration data
class UserRegistrationData {
  final String email;
  final String password;
  final String? fullName;
  final String? phone;

  const UserRegistrationData({
    required this.email,
    required this.password,
    this.fullName,
    this.phone,
  });
}

/// Interface for authentication repository operations
abstract class IAuthRepository {
  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Login with email and password
  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  });

  /// Register a new user
  Future<AuthResult> register({
    required UserRegistrationData data,
  });

  /// Login with phone number and OTP
  Future<AuthResult> loginWithPhone({
    required String phone,
    required String otp,
  });

  /// Send OTP to phone number
  Future<bool> sendPhoneOTP(String phone);

  /// Refresh authentication tokens
  Future<AuthResult> refreshTokens(String refreshToken);

  /// Logout current user
  Future<void> logout();

  /// Get current user profile
  Future<UserModel?> getCurrentUser();

  /// Update user profile
  Future<UserModel?> updateProfile({
    String? fullName,
    String? phone,
    String? email,
  });

  /// Reset password with email
  Future<bool> resetPassword(String email);

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}