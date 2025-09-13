import '../providers/users_provider.dart';
import '../models/user_model.dart';

class ProfileRepository {
  final UsersProvider _provider;
  ProfileRepository({required UsersProvider provider}) : _provider = provider;

  Future<UserModel> getProfile() => _provider.getProfile();

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) {
    return _provider.updateProfile(
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }
}
