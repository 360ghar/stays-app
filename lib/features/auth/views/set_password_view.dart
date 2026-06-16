import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';

/// Mandatory, non-skippable set-password screen shown after a passwordless OTP
/// verify (requirement 6). The user cannot leave until a password is set.
class SetPasswordView extends StatefulWidget {
  const SetPasswordView({super.key});

  @override
  State<SetPasswordView> createState() => _SetPasswordViewState();
}

class _SetPasswordViewState extends State<SetPasswordView> {
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

    // Block back navigation: this step is mandatory.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AutofillGroup(
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
                        Icons.lock_outline,
                        size: 40,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Set a Password',
                    style: textStyles.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Create a password to secure your account. '
                    'You will use it to sign in next time.',
                    style: textStyles.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (controller.pendingSetPasswordMaskedIdentifier !=
                      null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'For ${controller.pendingSetPasswordMaskedIdentifier}',
                        style: textStyles.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildPasswordField(
                    colors,
                    textStyles,
                    controllerField: _passwordController,
                    label: 'Password',
                    hint: 'Create a password (min. 6 characters)',
                    isConfirm: false,
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    colors,
                    textStyles,
                    controllerField: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    isConfirm: true,
                  ),
                  const SizedBox(height: 32),
                  Obx(
                    () => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 56,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : _handleSubmit,
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
                                'Continue',
                                style: textStyles.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    ColorScheme colors,
    TextTheme textStyles, {
    required TextEditingController controllerField,
    required String label,
    required String hint,
    required bool isConfirm,
  }) {
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
        Obx(() {
          final hasError = isConfirm
              ? controller.confirmPasswordError.value.isNotEmpty
              : controller.passwordError.value.isNotEmpty;
          final errorText = isConfirm
              ? controller.confirmPasswordError.value
              : controller.passwordError.value;
          return Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.elevatedSurface(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasError ? colors.error : colors.outlineVariant,
                    width: hasError ? 1.5 : 1,
                  ),
                ),
                child: TextFormField(
                  controller: controllerField,
                  obscureText: !controller.isPasswordVisible.value,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) {
                    if (isConfirm) {
                      controller.confirmPasswordError.value = '';
                    } else {
                      controller.passwordError.value = '';
                    }
                  },
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                    suffixIcon: isConfirm
                        ? null
                        : IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                            onPressed: controller.togglePasswordVisibility,
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
                    errorText,
                    style:
                        textStyles.bodySmall?.copyWith(color: colors.error) ??
                        TextStyle(color: colors.error, fontSize: 12),
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          );
        }),
      ],
    );
  }

  void _handleSubmit() {
    unawaited(
      controller.setPasswordAfterOtp(
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }
}
