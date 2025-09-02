import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class LoginResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  LoginResponse({required this.user, required this.accessToken, required this.refreshToken});

  factory LoginResponse.fromMap(Map<String, dynamic> map) => LoginResponse(
        user: UserModel.fromMap(map['user'] as Map<String, dynamic>),
        accessToken: map['accessToken'] as String,
        refreshToken: map['refreshToken'] as String,
      );
}

class AuthRepository {
  final AuthProvider _provider;
  AuthRepository({required AuthProvider provider}) : _provider = provider;

  Future<LoginResponse> login({required String email, required String password}) async {
    final json = await _provider.login(email: email, password: password);
    return LoginResponse.fromMap(json);
  }

  Future<void> logout(StorageService storage) async {
    final refresh = await storage.getRefreshToken();
    if (refresh != null) {
      await _provider.logout(refresh);
    }
  }
}
