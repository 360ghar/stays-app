class ProviderAuthResult {
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? rawUser;
  ProviderAuthResult({this.accessToken, this.refreshToken, this.rawUser});
}

abstract class IAuthProvider {
  Future<ProviderAuthResult> loginWithEmail({
    required String email,
    required String password,
  });

  Future<ProviderAuthResult> loginWithPhone({
    required String phone,
    required String password,
  });

  Future<ProviderAuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<bool> signUpWithPhone({
    required String phone,
    required String password,
  });

  Future<void> updatePassword({
    required String newPassword,
    String? currentPassword,
  });

  Future<void> logout();

  Future<Map<String, dynamic>?> getCurrentUserRaw();

  Future<bool> isAuthenticated();
}

