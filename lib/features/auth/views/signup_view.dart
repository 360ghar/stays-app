import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Create Account',
                style: textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sign up to get started',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildPhoneField(colors, textStyles),
              const SizedBox(height: 20),
              _buildPasswordField(colors, textStyles),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Password must be at least 6 characters long',
                  style: textStyles.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colors.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              _buildTermsCheckbox(colors, textStyles),
              const SizedBox(height: 24),
              Obx(
                () => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (controller.isLoading.value ||
                            !controller.isTermsAccepted.value)
                        ? null
                        : _handleSignup,
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
                            'Sign Up',
                            style: textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
                      style: textStyles.bodySmall?.copyWith(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: textStyles.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Text(
                      'Sign In',
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(ColorScheme colors, TextTheme textStyles) {
    return Obx(() {
      final hasError = controller.phoneError.value.isNotEmpty;
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
              border: Border.all(
                color: hasError ? colors.error : colors.outlineVariant,
                width: hasError ? 1.5 : 1,
              ),
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
                    onChanged: (_) => controller.phoneError.value = '',
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
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                controller.phoneError.value,
                style:
                    textStyles.bodySmall?.copyWith(color: colors.error) ??
                    TextStyle(color: colors.error, fontSize: 12),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      );
    });
  }

  Widget _buildPasswordField(ColorScheme colors, TextTheme textStyles) {
    return Obx(() {
      final hasError = controller.passwordError.value.isNotEmpty;
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
              onChanged: (_) => controller.passwordError.value = '',
              decoration: InputDecoration(
                hintText: 'Create a password (min. 6 characters)',
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
    });
  }

  Widget _buildTermsCheckbox(ColorScheme colors, TextTheme textStyles) {
    final linkStyle = textStyles.bodySmall?.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );
    return Obx(
      () => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: controller.isTermsAccepted.value,
              onChanged: (v) => controller.isTermsAccepted.value = v ?? false,
              activeColor: colors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _launchPolicy(
                        'https://360ghar.com/policies/terms-of-service',
                      ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: linkStyle,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _launchPolicy(
                        'https://360ghar.com/policies/privacy-policy',
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPolicy(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _handleSignup() async {
    if (!controller.isTermsAccepted.value) {
      Get.snackbar(
        'Terms required',
        'Please accept the Terms of Service and Privacy Policy to continue.',
      );
      return;
    }

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    var hasError = false;

    if (phone.isEmpty) {
      controller.phoneError.value = 'Phone number is required';
      hasError = true;
    } else if (phone.length != 10) {
      controller.phoneError.value =
          'Please enter a valid 10-digit phone number';
      hasError = true;
    }

    if (password.isEmpty) {
      controller.passwordError.value = 'Password is required';
      hasError = true;
    } else if (password.length < 6) {
      controller.passwordError.value = 'Password must be at least 6 characters';
      hasError = true;
    }

    if (hasError) return;

    final success = await controller.registerWithPhone(
      phone: phone,
      password: password,
    );

    if (success) {
      final otpController = Get.find<OTPController>();
      otpController.initializeOTP(
        type: OTPType.signup,
        phone: phone,
        password: password,
      );
      Get.toNamed(Routes.verification);
    }
  }
}
