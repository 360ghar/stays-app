import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../theme/theme_extensions.dart';

class PhoneLoginView extends StatefulWidget {
  const PhoneLoginView({super.key});

  @override
  State<PhoneLoginView> createState() => _PhoneLoginViewState();
}

class _PhoneLoginViewState extends State<PhoneLoginView> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
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
              Text(
                'Welcome Back',
                style: textStyles.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildPhoneField(colors, textStyles),
              const SizedBox(height: 24),
              _buildPasswordField(colors, textStyles),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember-me checkbox mirrors controller state via Obx.
                  Obx(() {
                    final rememberSelection = controller.rememberMe.value;
                    return InkWell(
                      onTap: () => controller.setRememberMe(!rememberSelection),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Checkbox(
                            value: rememberSelection,
                            onChanged: (value) =>
                                controller.setRememberMe(value ?? false),
                            activeColor: colors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style:
                                textStyles.bodyMedium?.copyWith(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ) ??
                                TextStyle(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: 14,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton(
                    onPressed: () => Get.toNamed(Routes.forgotPassword),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      textStyle: textStyles.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Obx(
                () => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : _handleLogin,
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
                            'Sign In',
                            style: textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colors.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colors.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: textStyles.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.toNamed(Routes.register),
                    child: Text(
                      'Sign Up',
                      style: textStyles.titleSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(ColorScheme colors, TextTheme textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
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
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: context.elevatedSurface(0.04),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  border: Border(
                    right: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      color: colors.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+91',
                      style: textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: '9876543210',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
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
            ],
          ),
        ),
        Obx(
          () => controller.phoneError.value.isEmpty
              ? const SizedBox(height: 4)
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    controller.phoneError.value,
                    style:
                        textStyles.bodySmall?.copyWith(color: colors.error) ??
                        TextStyle(color: colors.error, fontSize: 12),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(ColorScheme colors, TextTheme textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final hasError = controller.passwordError.value.isNotEmpty;
          return Column(
            children: [
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
                  controller: _passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
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
                  onChanged: (_) => controller.passwordError.value = '',
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    controller.passwordError.value,
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

  void _handleLogin() {
    controller.loginWithPhone(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
  }
}
