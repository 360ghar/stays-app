import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth/auth_controller.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final AuthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String phoneNumber = Get.arguments ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_outlined,
                    size: 40,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Set New Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Create a strong password for your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // New Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.passwordError.value.isEmpty 
                            ? Colors.grey.shade300 
                            : Colors.red,
                        width: controller.passwordError.value.isEmpty ? 1 : 2,
                      ),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      onChanged: (_) => controller.passwordError.value = '',
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value 
                              ? Icons.visibility_off_outlined 
                              : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  )),
                  Obx(() => controller.passwordError.value.isEmpty
                    ? const SizedBox(height: 4)
                    : Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          controller.passwordError.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Confirm Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.confirmPasswordError.value.isEmpty 
                            ? Colors.grey.shade300 
                            : Colors.red,
                        width: controller.confirmPasswordError.value.isEmpty ? 1 : 2,
                      ),
                    ),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !controller.isPasswordVisible.value,
                      onChanged: (_) => controller.confirmPasswordError.value = '',
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value 
                              ? Icons.visibility_off_outlined 
                              : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  )),
                  Obx(() => controller.confirmPasswordError.value.isEmpty
                    ? const SizedBox(height: 4)
                    : Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          controller.confirmPasswordError.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Password Requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password requirements:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• At least 6 characters long\n• Both passwords must match',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Reset Password Button
              Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value 
                    ? null 
                    : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              )),
              
              const SizedBox(height: 48),
              
              // Security Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your password will be encrypted and stored securely.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _handleResetPassword() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    // Validate locally first
    bool hasError = false;
    
    if (password.isEmpty) {
      controller.passwordError.value = 'Password is required';
      hasError = true;
    } else if (password.length < 6) {
      controller.passwordError.value = 'Password must be at least 6 characters';
      hasError = true;
    }
    
    if (confirmPassword.isEmpty) {
      controller.confirmPasswordError.value = 'Please confirm your password';
      hasError = true;
    } else if (password != confirmPassword) {
      controller.confirmPasswordError.value = 'Passwords do not match';
      hasError = true;
    }
    
    if (hasError) return;
    
    controller.resetPassword(
      newPassword: password,
      confirmPassword: confirmPassword,
    );
  }
}