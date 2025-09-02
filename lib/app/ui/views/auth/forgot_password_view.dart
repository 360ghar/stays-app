import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../../utils/helpers/validator_helper.dart';

class ForgotPasswordView extends GetView<AuthController> {
  const ForgotPasswordView({super.key});
  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                controller: emailCtrl,
                validator: ValidatorHelper.email,
              ),
              const SizedBox(height: 20),
              Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              await controller.forgotPassword(emailCtrl.text.trim());
                            }
                          },
                    child: controller.isLoading.value
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Send Reset Link'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
