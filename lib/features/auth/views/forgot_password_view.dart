import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _identifierController = TextEditingController();
  late final AuthController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _identifierController.dispose();
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
                    color: colors.secondaryContainer.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_outlined,
                    size: 40,
                    color: colors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Forgot Password?',
                style: textStyles.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'No worries! Enter your email or phone number and we\'ll send a code to reset your password.',
                style: textStyles.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildIdentifierField(colors, textStyles),
              const SizedBox(height: 48),
              Obx(
                () => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : _handleSendOTP,
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
                            'Send Code',
                            style: textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Remember your password? ",
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
              const SizedBox(height: 32),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdentifierField(ColorScheme colors, TextTheme textStyles) {
    return Obx(() {
      final hasError = controller.phoneError.value.isNotEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email or Phone',
            style: textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.elevatedSurface(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? colors.error : colors.outlineVariant,
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: TextFormField(
              controller: _identifierController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.telephoneNumber,
                AutofillHints.username,
              ],
              onChanged: (_) => controller.phoneError.value = '',
              decoration: InputDecoration(
                hintText: 'you@example.com or 9876543210',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                prefixIcon: Icon(
                  Icons.alternate_email,
                  color: colors.onSurface.withValues(alpha: 0.6),
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
              onFieldSubmitted: (_) => _handleSendOTP(),
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

  Future<void> _handleSendOTP() async {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      controller.phoneError.value = 'Email or phone number is required';
      return;
    }

    // Email channel: OTP via email (decision 1 — OTP for both channels).
    if (GetUtils.isEmail(identifier)) {
      final success = await controller.sendForgotPasswordEmailOtp(identifier);
      if (success) {
        final otpController = Get.find<OTPController>();
        otpController.initializeOTP(
          type: OTPType.forgotPassword,
          email: identifier,
        );
        await Get.toNamed(Routes.verification);
      }
      return;
    }

    // Phone channel.
    final phone = identifier.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length != 10) {
      controller.phoneError.value =
          'Please enter a valid 10-digit phone number';
      return;
    }

    final success = await controller.sendForgotPasswordOTP(phone);
    if (success) {
      final otpController = Get.find<OTPController>();
      otpController.initializeOTP(type: OTPType.forgotPassword, phone: phone);
      await Get.toNamed(Routes.verification);
    }
  }
}
