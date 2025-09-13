import 'base_provider.dart';
import '../models/user_model.dart';

class UsersProvider extends BaseProvider {
  Future<UserModel> getProfile() async {
    final res = await get('/api/v1/users/profile/');
    return handleResponse(res, (json) {
      final data = json['data'] ?? json;
      return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    // Backend expects full_name
    final computedFullName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : [
            firstName,
            lastName,
          ].where((e) => (e ?? '').trim().isNotEmpty).join(' ').trim();
    if (computedFullName.isNotEmpty) body['full_name'] = computedFullName;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['profile_image_url'] = avatarUrl;

    final res = await put('/api/v1/users/profile/', body);
    return handleResponse(res, (json) {
      final data = json['data'] ?? json;
      return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
    });
  }
}
