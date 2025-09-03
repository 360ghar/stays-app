import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../../utils/helpers/validator_helper.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First name'),
                controller: firstNameCtrl,
                validator: ValidatorHelper.requiredField,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last name'),
                controller: lastNameCtrl,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: emailCtrl,
                validator: ValidatorHelper.email,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                controller: passwordCtrl,
                obscureText: true,
                validator: ValidatorHelper.requiredField,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              await controller.register(
                                firstName: firstNameCtrl.text.trim(),
                                lastName: lastNameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                              );
                            }
                          },
                    child: controller.isLoading.value
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign Up'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
