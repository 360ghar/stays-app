import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:smart_auth/smart_auth.dart';

import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/auth/controllers/otp_controller.dart';
import 'package:stays_app/app/data/providers/auth/i_auth_provider.dart';
import 'package:stays_app/app/data/services/remember_me_service.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/ui/theme/theme_extensions.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';

/// Login entry screen implementing the unified, Google-first state-machine:
/// identifier -> /auth/identifier-status -> password (verified) | OTP-first.
class PhoneLoginView extends StatefulWidget {
  const PhoneLoginView({super.key});

  @override
  State<PhoneLoginView> createState() => _PhoneLoginViewState();
}

enum _LoginStep { identifier, password }

class _PhoneLoginViewState extends State<PhoneLoginView> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthController controller;

  _LoginStep _step = _LoginStep.identifier;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isEmail => GetUtils.isEmail(_identifierController.text.trim());

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: _step == _LoginStep.password
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: colors.onSurface),
                onPressed: _backToIdentifier,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AutofillGroup(
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
                  _step == _LoginStep.identifier
                      ? 'Sign in or create an account to continue'
                      : 'Enter your password',
                  style: textStyles.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildLastMethodHint(colors, textStyles),
                if (_step == _LoginStep.identifier) ...[
                  _buildGoogleButton(colors, textStyles),
                  _buildAppleButton(colors, textStyles),
                  const SizedBox(height: 24),
                  _buildDivider(colors, textStyles),
                  const SizedBox(height: 24),
                  _buildIdentifierField(colors, textStyles),
                  const SizedBox(height: 24),
                  Obx(
                    () => _buildPrimaryButton(
                      label: 'Continue',
                      loading: controller.isLoading.value,
                      onPressed: _handleContinue,
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ),
                ] else ...[
                  _buildPasswordField(colors, textStyles),
                  const SizedBox(height: 16),
                  _buildRememberRow(colors, textStyles),
                  const SizedBox(height: 24),
                  Obx(
                    () => _buildPrimaryButton(
                      label: 'Sign In',
                      loading: controller.isLoading.value,
                      onPressed: _handlePasswordLogin,
                      colors: colors,
                      textStyles: textStyles,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildSignupRow(colors, textStyles),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _buildLastMethodHint(ColorScheme colors, TextTheme textStyles) {
    return Obx(() {
      final method = controller.lastMethod.value;
      final masked = controller.lastIdentifierMasked.value;
      if (method == null) return const SizedBox.shrink();
      final label = _lastMethodLabel(method);
      if (label == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.history, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  masked == null
                      ? 'Last time you used $label'
                      : 'Last time you used $label ($masked)',
                  style: textStyles.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildGoogleButton(ColorScheme colors, TextTheme textStyles) {
    return Obx(
      () => SizedBox(
        height: 56,
        child: OutlinedButton.icon(
          onPressed: controller.isGoogleLoading.value
              ? null
              : controller.loginWithGoogle,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: controller.isGoogleLoading.value
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                )
              : _googleGlyph(colors),
          label: Text(
            'Continue with Google',
            style: textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleGlyph(ColorScheme colors) {
    // No bundled Google logo asset; render a recognizable "G" badge.
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colors.primary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildAppleButton(ColorScheme colors, TextTheme textStyles) {
    // iOS only, and only when the OS reports Apple Sign-In is available.
    if (!Platform.isIOS) return const SizedBox.shrink();
    return Obx(() {
      if (!controller.isAppleSignInAvailable.value) {
        return const SizedBox.shrink();
      }
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          height: 56,
          child: controller.isAppleLoading.value
              ? Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    ),
                  ),
                )
              : SignInWithAppleButton(
                  onPressed: controller.loginWithApple,
                  borderRadius: BorderRadius.circular(12),
                  style: isDark
                      ? SignInWithAppleButtonStyle.white
                      : SignInWithAppleButtonStyle.black,
                ),
        ),
      );
    });
  }

  Widget _buildDivider(ColorScheme colors, TextTheme textStyles) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: colors.outlineVariant.withValues(alpha: 0.6)),
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
          child: Divider(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
      ],
    );
  }

  Widget _buildIdentifierField(ColorScheme colors, TextTheme textStyles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Email or Phone',
              style: textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            if (Platform.isAndroid)
              TextButton.icon(
                onPressed: _pickPhoneHint,
                icon: const Icon(Icons.phone_android, size: 16),
                label: const Text('Use phone'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.elevatedSurface(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [
              AutofillHints.email,
              AutofillHints.telephoneNumber,
              AutofillHints.username,
            ],
            onChanged: (_) => controller.emailOrPhoneError.value = '',
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
            onFieldSubmitted: (_) => _handleContinue(),
          ),
        ),
        Obx(
          () => controller.emailOrPhoneError.value.isEmpty
              ? const SizedBox(height: 4)
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    controller.emailOrPhoneError.value,
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
                  autofillHints: const [AutofillHints.password],
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
                  onFieldSubmitted: (_) => _handlePasswordLogin(),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.toNamed(Routes.forgotPassword),
                  style: TextButton.styleFrom(foregroundColor: colors.primary),
                  child: const Text('Forgot Password?'),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRememberRow(ColorScheme colors, TextTheme textStyles) {
    return Obx(() {
      final rememberSelection = controller.rememberMe.value;
      return InkWell(
        onTap: () => controller.setRememberMe(!rememberSelection),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Checkbox(
              value: rememberSelection,
              onChanged: (value) => controller.setRememberMe(value ?? false),
              activeColor: colors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: textStyles.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPrimaryButton({
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

  Widget _buildSignupRow(ColorScheme colors, TextTheme textStyles) {
    return Row(
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
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _pickPhoneHint() async {
    try {
      final res = await SmartAuth.instance.requestPhoneNumberHint();
      final phone = res.data;
      if (phone != null && phone.isNotEmpty) {
        // Normalize to local digits where possible; keep as-is otherwise.
        final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
        final local = digits.length > 10
            ? digits.substring(digits.length - 10)
            : digits;
        _identifierController.text = local;
        controller.emailOrPhoneError.value = '';
      }
    } catch (_) {
      // Hint picker unavailable / dismissed — silently ignore.
    }
  }

  Future<void> _handleContinue() async {
    final identifier = _identifierController.text.trim();
    final IdentifierStatus? status = await controller.checkIdentifierStatus(
      identifier,
    );
    if (status == null) return;

    if (status.isPasswordStep) {
      // Verified account with a password -> ask for password inline.
      setState(() => _step = _LoginStep.password);
      return;
    }

    if (status.exists && !status.verified) {
      AppSnackbar.info(
        title: 'Verify Your Account',
        message:
            "Your account isn't verified yet. We've sent a code — enter it below or resend.",
      );
    }

    // OTP-first path (unverified or unknown account). Only an UNKNOWN
    // identifier should create a new user; an existing-but-unverified account
    // must not be duplicated.
    if (status.isEmail || _isEmail) {
      final sent = await controller.sendEmailOtp(
        identifier,
        shouldCreateUser: !status.exists,
      );
      if (sent) {
        final otpController = Get.find<OTPController>();
        // Requirement 6: if the account has no password (incl. unknown
        // identifier), force a mandatory set-password after the OTP verify.
        otpController.initializeOTP(
          type: OTPType.emailOtp,
          email: identifier,
          requirePasswordSetup: !status.hasPassword,
          emailShouldCreateUser: !status.exists,
        );
        await Get.toNamed(Routes.verification);
      }
    } else {
      // Phone identifier: route to the existing phone signup/OTP flow.
      AppSnackbar.info(
        title: 'Verify Your Phone',
        message: 'Set a password and we will text you a verification code.',
      );
      await Get.toNamed(Routes.register, arguments: {'phone': identifier});
    }
  }

  Future<void> _handlePasswordLogin() async {
    final identifier = _identifierController.text.trim();
    await controller.login(
      email: identifier,
      password: _passwordController.text,
    );
  }

  void _backToIdentifier() {
    setState(() {
      _step = _LoginStep.identifier;
      _passwordController.clear();
      controller.passwordError.value = '';
    });
  }

  String? _lastMethodLabel(String method) {
    switch (method) {
      case AuthMethods.google:
        return 'Google';
      case AuthMethods.apple:
        return 'Apple';
      case AuthMethods.emailPassword:
        return 'email + password';
      case AuthMethods.phonePassword:
        return 'phone + password';
      case AuthMethods.emailOtp:
        return 'email code';
      case AuthMethods.phoneOtp:
        return 'phone code';
    }
    return null;
  }
}
