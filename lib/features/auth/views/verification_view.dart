import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';

import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';

/// OTP verification screen. Handles phone-SMS, email, and the post-Google
/// add-phone flows, with Android SMS autofill via [CodeAutoFill].
class VerificationView extends StatefulWidget {
  const VerificationView({super.key});

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> with CodeAutoFill {
  late final OTPController controller;
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<OTPController>();
    // Listen for incoming SMS codes on Android (no-op elsewhere). Skip when the
    // active flow uses email (email-OTP login or email password reset).
    if (Platform.isAndroid && !controller.isEmailChannel) {
      listenForCode();
    }
  }

  @override
  void codeUpdated() {
    final received = code;
    if (received != null && received.isNotEmpty) {
      controller.fillCode(received);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    if (Platform.isAndroid) {
      unawaited(cancel());
    }
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
        actions: [
          // Skip is only meaningful for the optional post-Google add-phone flow.
          if (controller.isAddPhoneFlow)
            TextButton(
              onPressed: controller.skipAddPhone,
              child: Text(
                'Skip',
                style: textStyles.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            // Add-phone flow first asks for the phone number to verify.
            if (controller.isAddPhoneFlow &&
                controller.awaitingPhoneEntry.value) {
              return _buildPhoneEntry(context, colors, textStyles);
            }
            return _buildCodeEntry(context, colors, textStyles);
          }),
        ),
      ),
    );
  }

  Widget _buildPhoneEntry(
    BuildContext context,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(child: _buildIconBadge(colors, Icons.phone_outlined)),
          const SizedBox(height: 32),
          Text(
            'Add a phone number',
            style: textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Add a phone to secure your account. You can skip this for now.',
            style: textStyles.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: context.elevatedSurface(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Text(
                    '+91',
                    style: textStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 18,
                      ),
                      hintStyle: textStyles.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => _primaryButton(
              label: 'Send Code',
              loading: controller.isLoading.value,
              onPressed: () =>
                  controller.submitAddPhone(_phoneController.text.trim()),
              colors: colors,
              textStyles: textStyles,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeEntry(
    BuildContext context,
    ColorScheme colors,
    TextTheme textStyles,
  ) {
    final isEmail = controller.isEmailChannel;
    final destination = isEmail
        ? (controller.email ?? '')
        : '+91 ${controller.phoneNumber}';

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: _buildIconBadge(
              colors,
              isEmail ? Icons.mail_outline : Icons.message_outlined,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isEmail ? 'Check Your Email' : 'Verify Your Number',
            style: textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'We sent a 6-digit code to '),
                TextSpan(
                  text: destination,
                  style: textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              6,
              (index) => _buildOTPField(context, index),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.otpError.value.isEmpty) {
              return const SizedBox(height: 20);
            }
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.errorContainer),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.otpError.value,
                      style: textStyles.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
          Obx(
            () => _primaryButton(
              label: 'Verify Code',
              loading: controller.isLoading.value,
              onPressed: controller.verifyOTP,
              colors: colors,
              textStyles: textStyles,
            ),
          ),
          const SizedBox(height: 32),
          Column(
            children: [
              Text(
                'Didn\'t receive the code?',
                style: textStyles.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Obx(() {
                if (!controller.canResend.value) {
                  return Text(
                    'Resend in ${controller.countdown.value}s',
                    style: textStyles.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  );
                }
                return GestureDetector(
                  onTap: controller.resendOTP,
                  child: Text(
                    'Resend',
                    style: textStyles.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 60),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildIconBadge(ColorScheme colors, IconData icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: colors.primary),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool loading,
    required VoidCallback onPressed,
    required ColorScheme colors,
    required TextTheme textStyles,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 2,
          shadowColor: colors.primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                ),
              )
            : Text(
                label,
                style: textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onPrimary,
                ),
              ),
      ),
    );
  }

  Widget _buildOTPField(BuildContext context, int index) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Container(
      width: 56,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant, width: 1.5),
        color: context.elevatedSurface(0.06),
      ),
      child: TextFormField(
        controller: controller.otpControllers[index],
        focusNode: controller.otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        // Only the first field carries the oneTimeCode hint so iOS/Android
        // surface the autofill affordance once for the group.
        autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: textStyles.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colors.onSurface,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => controller.onOTPChanged(index, value),
        onTap: () {
          final selection = controller.otpControllers[index].selection;
          controller.otpControllers[index].selection = selection.copyWith(
            baseOffset: 0,
            extentOffset: controller.otpControllers[index].text.length,
          );
        },
      ),
    );
  }
}
