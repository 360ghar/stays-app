import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../theme/theme_extensions.dart';

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
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_outlined,
                    size: 40,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Set New Password',
                style: textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Create a strong password for your account',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildPasswordField(
                label: 'New Password',
                controller: _passwordController,
                errorStream: controller.passwordError,
                onChanged: (_) => controller.passwordError.value = '',
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                errorStream: controller.confirmPasswordError,
                onChanged: (_) => controller.confirmPasswordError.value = '',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password requirements:',
                      style: textStyles.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• At least 6 characters long\n• Both passwords must match',
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.onSecondaryContainer.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Obx(
                () => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 2,
                      shadowColor: colors.primary.withValues(alpha: 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Reset Password',
                            style: textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.elevatedSurface(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: colors.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your password will be encrypted and stored securely.',
                        style: textStyles.bodySmall?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ) ??
                            TextStyle(
                              fontSize: 12,
                              color: colors.onSurface.withValues(alpha: 0.7),
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required RxString errorStream,
    required ValueChanged<String> onChanged,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Obx(
      () {
        final hasError = errorStream.value.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.elevatedSurface(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError ? colors.error : colors.outlineVariant,
                  width: hasError ? 1.5 : 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: !this.controller.isPasswordVisible.value,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: label == 'New Password'
                      ? 'Enter new password'
                      : 'Confirm new password',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      this.controller.isPasswordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: this.controller.togglePasswordVisibility,
                  ),
                  hintStyle: textStyles.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                style: textStyles.bodyMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorStream.value,
                  style: textStyles.bodySmall?.copyWith(color: colors.error) ??
                      TextStyle(color: colors.error, fontSize: 12),
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  void _handleResetPassword() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    var hasError = false;

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
