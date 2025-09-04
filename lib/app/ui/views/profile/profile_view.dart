import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/phone_auth_controller.dart';
import '../../../routes/app_routes.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<PhoneAuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Your Account'),
            subtitle: Text('Manage profile and preferences'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Payment methods'),
            onTap: () => Get.toNamed(Routes.paymentMethods),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }
}
