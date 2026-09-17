import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart' hide Response;
import 'package:go_router/go_router.dart';

import 'package:stays_app/app/data/models/user_model.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/core/router/app_router.dart';
import 'package:stays_app/core/theme/tokens.dart';
import 'package:stays_app/features/auth/providers/auth_providers.dart';

final _profileUserProvider = FutureProvider.autoDispose<UserModel?>((
  ref,
) async {
  if (!Get.isRegistered<AuthRepository>()) return null;
  try {
    return await Get.find<AuthRepository>().getCurrentUser();
  } catch (_) {
    return null;
  }
});

/// V2 profile. Header, shortcuts, logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_profileUserProvider);
    final user = userAsync.valueOrNull;
    return Scaffold(
      backgroundColor: StayTokens.paper,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(StayTokens.s16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: StayTokens.paperWarm,
                backgroundImage: user?.avatarUrl?.isNotEmpty == true
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl?.isNotEmpty == true
                    ? null
                    : const Icon(
                        Icons.person,
                        size: 32,
                        color: StayTokens.inkSecondary,
                      ),
              ),
              const SizedBox(width: StayTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? 'Guest', style: StayTokens.title),
                    if (user?.email?.isNotEmpty == true)
                      Text(user!.email!, style: StayTokens.bodySecondary),
                    if (user?.phone?.isNotEmpty == true)
                      Text(user!.phone!, style: StayTokens.bodySecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: StayTokens.s24),
          _Row(
            icon: Icons.card_travel_outlined,
            label: 'My trips',
            onTap: () => context.push(AppPaths.trips),
          ),
          _Row(
            icon: Icons.favorite_border,
            label: 'Wishlist',
            onTap: () => context.push(AppPaths.wishlist),
          ),
          _Row(
            icon: Icons.credit_card_outlined,
            label: 'Payment methods',
            onTap: () => context.push(AppPaths.paymentMethods),
          ),
          _Row(
            icon: Icons.inbox_outlined,
            label: 'Inbox',
            onTap: () => context.push(AppPaths.inbox),
          ),
          const SizedBox(height: StayTokens.s24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppPaths.login);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: StayTokens.s12),
      child: ListTile(
        leading: Icon(icon, color: StayTokens.inkSecondary),
        title: Text(label, style: StayTokens.body),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
