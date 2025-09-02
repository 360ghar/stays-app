import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/helpers/validator_helper.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                key: const Key('email_field'),
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: ValidatorHelper.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('password_field'),
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: ValidatorHelper.requiredField,
              ),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton(
                    key: const Key('login_button'),
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              await controller.login(
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                              );
                            }
                          },
                    child: controller.isLoading.value
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Log In'),
                  )),
              TextButton(
                onPressed: () => Get.toNamed(Routes.register),
                child: const Text('Create an account'),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.forgotPassword),
                child: const Text('Forgot Password?'),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.verification),
                child: const Text('Verify Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
