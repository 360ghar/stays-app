import 'package:flutter_test/flutter_test.dart';
import 'package:stays_app/app/data/models/user_model.dart';

void main() {
  group('UserModel.fromMap backend contract', () {
    test('reads supabase_user_id and stringifies int id', () {
      final user = UserModel.fromMap({
        'id': 42,
        'supabase_user_id': 'aaaa-bbbb-cccc',
        'email': 'guest@example.com',
        'full_name': 'Guest User',
        'profile_image_url': 'https://cdn.example/u.jpg',
      });

      expect(user.id, '42');
      expect(user.supabaseId, 'aaaa-bbbb-cccc');
      expect(user.name, 'Guest User');
      expect(user.profileImageUrl, 'https://cdn.example/u.jpg');
    });

    test('does not prefer dead supabase_id over supabase_user_id', () {
      final user = UserModel.fromMap({
        'id': 1,
        'supabase_user_id': 'canonical',
        'supabase_id': 'legacy',
      });
      expect(user.supabaseId, 'canonical');
    });
  });
}
