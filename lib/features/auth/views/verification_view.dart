import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';

class VerificationView extends GetView<OTPController> {
  const VerificationView({super.key});

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
                    Icons.message_outlined,
                    size: 40,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Verify Your Number',
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
                      text: '+91 ${controller.phoneNumber}',
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.verifyOTP,
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
                            'Verify Code',
                            style: textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onPrimary,
                            ),
                          ),
                  ),
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
