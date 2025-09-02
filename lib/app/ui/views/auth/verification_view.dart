import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/verification_controller.dart';

class VerificationView extends GetView<VerificationController> {
  const VerificationView({super.key});
  @override
  Widget build(BuildContext context) {
    final tokenCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Verification token'),
              controller: tokenCtrl,
            ),
            const SizedBox(height: 20),
            Obx(() => ElevatedButton(
                  onPressed: controller.isVerifying.value
                      ? null
                      : () async => controller.verifyEmail(tokenCtrl.text.trim()),
                  child: controller.isVerifying.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Verify'),
                )),
          ],
        ),
      ),
    );
  }
}
