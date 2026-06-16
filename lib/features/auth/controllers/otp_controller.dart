import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stays_app/app/data/services/remember_me_service.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/app/utils/logger/app_logger.dart';
import 'auth_controller.dart';

/// OTP flows handled by [OTPController].
/// - [signup]: phone signup verification (SMS), then auto-login.
/// - [forgotPassword]: phone OTP for password reset.
/// - [emailOtp]: 6-digit email OTP login (passwordless or pre-password).
/// - [addPhone]: post-Google add-and-verify phone (skippable).
enum OTPType { signup, forgotPassword, emailOtp, addPhone }

class OTPController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  // Standard resend cooldown shared by every OTP mode (phone/email/add-phone).
  static const int resendCountdownSeconds = 30;

  final RxBool isLoading = false.obs;
  final RxString otpError = ''.obs;
  final RxInt countdown = resendCountdownSeconds.obs;
  final RxBool canResend = false.obs;

  // True once a phone has been submitted in the add-phone flow (so the UI
  // switches from "enter phone" to "enter code").
  final RxBool awaitingPhoneEntry = false.obs;

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  late OTPType otpType;
  late String phoneNumber;
  String? email;
  String? signupPassword;

  /// When true, the account has no password yet and the user MUST set one
  /// (non-skippable) after a successful OTP verify (requirement 6).
  bool requirePasswordSetup = false;

  /// Mirrors the `shouldCreateUser` used for the original email-OTP send, so a
  /// resend reuses it (signup sends with `true`; login/reset with `false`).
  bool _emailShouldCreateUser = false;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // The 30s resend cooldown is (re)started whenever a code is actually sent:
    // for phone/email flows that happens just before navigation (initializeOTP),
    // and for the add-phone flow after the number is submitted (submitAddPhone).
    if (!awaitingPhoneEntry.value) {
      _startCountdown();
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.onClose();
  }

  void initializeOTP({
    required OTPType type,
    String phone = '',
    String? email,
    String? password,
    bool requirePasswordSetup = false,
    bool emailShouldCreateUser = false,
  }) {
    otpType = type;
    phoneNumber = phone;
    this.email = email;
    signupPassword = password;
    this.requirePasswordSetup = requirePasswordSetup;
    _emailShouldCreateUser = emailShouldCreateUser;
    // For add-phone, we first need the user to enter their phone number.
    awaitingPhoneEntry.value = type == OTPType.addPhone && phone.isEmpty;

    // A code has just been sent for the code-entry flows (phone/email, or
    // add-phone with a pre-filled number) — (re)start the shared 30s cooldown.
    // The add-phone phone-entry step has no code yet, so cancel any countdown
    // started at construction time; it begins after the number is submitted.
    if (awaitingPhoneEntry.value) {
      _stopCountdown();
    } else {
      _startCountdown();
    }
  }

  bool get isEmailFlow => otpType == OTPType.emailOtp;

  /// True when the active flow targets an email channel — either email-OTP
  /// login or an email-channel password reset. Drives the verification UI
  /// (destination text, icon) and disables SMS autofill.
  bool get isEmailChannel => email != null && email!.isNotEmpty;

  bool get isAddPhoneFlow => otpType == OTPType.addPhone;

  /// Starts (or restarts) the shared 30-second resend cooldown: disables
  /// resend, counts down to 0, then enables it. Used by every OTP mode.
  void _startCountdown() {
    canResend.value = false;
    countdown.value = resendCountdownSeconds;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  /// Cancels any running cooldown (used by the add-phone phone-entry step,
  /// where no code has been sent yet so resend is not applicable).
  void _stopCountdown() {
    _timer?.cancel();
    countdown.value = resendCountdownSeconds;
    canResend.value = false;
  }

  void onOTPChanged(int index, String value) {
    otpError.value = '';

    if (value.isNotEmpty) {
      if (value.length == 1) {
        // Move to next field if not the last one
        if (index < otpControllers.length - 1) {
          otpFocusNodes[index + 1].requestFocus();
        } else {
          // If last field, unfocus
          otpFocusNodes[index].unfocus();
          // Auto-verify if all fields are filled
          _autoVerifyIfComplete();
        }
      } else if (value.length > 1) {
        // Handle paste - split the value across fields
        final chars = value.split('');
        for (
          int i = 0;
          i < chars.length && (index + i) < otpControllers.length;
          i++
        ) {
          otpControllers[index + i].text = chars[i];
        }
        // Focus the last filled field or unfocus if complete
        final lastFilledIndex = (index + chars.length - 1).clamp(
          0,
          otpControllers.length - 1,
        );
        if (lastFilledIndex == otpControllers.length - 1) {
          otpFocusNodes[lastFilledIndex].unfocus();
          _autoVerifyIfComplete();
        } else {
          otpFocusNodes[lastFilledIndex + 1].requestFocus();
        }
      }
    }
  }

  void onOTPBackspace(int index) {
    if (otpControllers[index].text.isEmpty && index > 0) {
      // Move to previous field and clear it
      otpFocusNodes[index - 1].requestFocus();
      otpControllers[index - 1].clear();
    }
  }

  /// Fills the OTP fields from an autofilled SMS code (sms_autofill) and
  /// triggers verification when complete.
  void fillCode(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return;
    for (var i = 0; i < otpControllers.length; i++) {
      otpControllers[i].text = i < digits.length ? digits[i] : '';
    }
    otpError.value = '';
    _autoVerifyIfComplete();
  }

  void _autoVerifyIfComplete() {
    final otp = getEnteredOTP();
    if (otp.length == 6) {
      unawaited(verifyOTP());
    }
  }

  String getEnteredOTP() {
    return otpControllers.map((controller) => controller.text).join();
  }

  void clearOTP() {
    for (final controller in otpControllers) {
      controller.clear();
    }
    otpError.value = '';
    otpFocusNodes[0].requestFocus();
  }

  /// In the add-phone flow, submit the phone number and trigger a verify SMS.
  Future<void> submitAddPhone(String phone) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      otpError.value = '';
      final sent = await _authController.addPhone(phone);
      if (sent) {
        phoneNumber = phone;
        awaitingPhoneEntry.value = false;
        _startCountdown();
        AppSnackbar.success(
          title: 'Code Sent',
          message: 'We sent a 6-digit code to +91 $phone',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOTP() async {
    // Add guard clause to prevent double-submits
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      otpError.value = '';

      final enteredOTP = getEnteredOTP();

      if (enteredOTP.length != 6) {
        otpError.value = 'Please enter complete OTP';
        return;
      }

      switch (otpType) {
        case OTPType.emailOtp:
          await _handleEmailOtp(enteredOTP);
          break;
        case OTPType.addPhone:
          await _handleAddPhoneOtp(enteredOTP);
          break;
        case OTPType.signup:
          await _verifyPhoneSms(enteredOTP);
          await _handleSignupSuccess();
          break;
        case OTPType.forgotPassword:
          // Channel-aware: email reset verifies via email OTP, phone via SMS.
          if (email != null && email!.isNotEmpty) {
            await _verifyEmailCode(enteredOTP);
          } else {
            await _verifyPhoneSms(enteredOTP);
          }
          _handleForgotPasswordSuccess();
          break;
      }
    } catch (e) {
      AppLogger.warning('OTP verification failed: $e');
      otpError.value = 'Invalid or expired OTP. Please try again';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _verifyPhoneSms(String otp) async {
    final formattedPhone = phoneNumber.startsWith('+')
        ? phoneNumber
        : '+91$phoneNumber';
    await Supabase.instance.client.auth.verifyOTP(
      phone: formattedPhone,
      token: otp,
      type: OtpType.sms,
    );
  }

  // Verifies an email OTP (type: email), establishing a session. Used by the
  // email-channel forgot-password flow.
  Future<void> _verifyEmailCode(String otp) async {
    await Supabase.instance.client.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
  }

  Future<void> _handleEmailOtp(String otp) async {
    final emailAddress = email;
    if (emailAddress == null || emailAddress.isEmpty) {
      otpError.value = 'Missing email address. Please restart sign in.';
      return;
    }
    await _authController.verifyEmailOtp(email: emailAddress, token: otp);
    // Requirement 6: passwordless OTP accounts must set a password before
    // entering the app (non-skippable). The set-password step overwrites the
    // recorded last-method to email_password on success.
    if (requirePasswordSetup) {
      _authController.startMandatorySetPassword(
        method: AuthMethods.emailPassword,
        identifier: emailAddress,
      );
      return;
    }
    _showSuccessSnackbar('Signed in successfully!');
    await Get.offAllNamed(Routes.home);
  }

  Future<void> _handleAddPhoneOtp(String otp) async {
    await _authController.verifyAddPhoneOtp(phone: phoneNumber, token: otp);
    _showSuccessSnackbar('Phone number verified!');
    await Get.offAllNamed(Routes.home);
  }

  Future<void> _handleSignupSuccess() async {
    // Complete signup process
    _showSuccessSnackbar('Account created successfully!');

    // Auto login after successful signup (the signup screen already collected
    // a password, so the account is not passwordless).
    if (signupPassword != null) {
      await _authController.loginWithPhone(
        phone: phoneNumber.replaceAll('+91', ''),
        password: signupPassword!,
      );
      return;
    }

    // Passwordless phone OTP verify: requirement 6 forces a set-password step.
    if (requirePasswordSetup) {
      _authController.startMandatorySetPassword(
        method: AuthMethods.phonePassword,
        identifier: phoneNumber,
      );
      return;
    }

    await Get.offAllNamed(Routes.login);
  }

  void _handleForgotPasswordSuccess() {
    _showSuccessSnackbar('OTP verified successfully!');
    // Navigate to reset password screen with the active identifier (email or
    // phone) for display.
    final identifier = (email != null && email!.isNotEmpty)
        ? email!
        : phoneNumber;
    unawaited(Get.toNamed(Routes.resetPassword, arguments: identifier));
  }

  /// Skip the (optional) post-Google/Apple add-phone step. The last_auth_method
  /// was already recorded at sign-in time, so we only navigate home.
  Future<void> skipAddPhone() async {
    await Get.offAllNamed(Routes.home);
  }

  Future<void> resendOTP() async {
    try {
      isLoading.value = true;
      switch (otpType) {
        case OTPType.emailOtp:
          final emailAddress = email;
          if (emailAddress != null && emailAddress.isNotEmpty) {
            await _authController.resendEmailOtp(
              emailAddress,
              shouldCreateUser: _emailShouldCreateUser,
            );
          }
          break;
        case OTPType.addPhone:
          if (phoneNumber.isNotEmpty) {
            await _authController.addPhone(phoneNumber);
          }
          break;
        case OTPType.forgotPassword:
          // Email-channel reset re-sends an email OTP; phone re-sends SMS.
          if (email != null && email!.isNotEmpty) {
            await _authController.sendForgotPasswordEmailOtp(email!);
          } else {
            final formattedPhone = phoneNumber.startsWith('+')
                ? phoneNumber
                : '+91$phoneNumber';
            await Supabase.instance.client.auth.resend(
              type: OtpType.sms,
              phone: formattedPhone,
            );
          }
          break;
        case OTPType.signup:
          final formattedPhone = phoneNumber.startsWith('+')
              ? phoneNumber
              : '+91$phoneNumber';
          await Supabase.instance.client.auth.resend(
            type: OtpType.sms,
            phone: formattedPhone,
          );
          break;
      }
      _showSuccessSnackbar('OTP resent successfully!');
      _startCountdown();
      clearOTP();
    } catch (e) {
      _showErrorSnackbar('Failed to resend OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void _showSuccessSnackbar(String message) {
    AppSnackbar.success(title: 'Success', message: message);
  }

  void _showErrorSnackbar(String message) {
    AppSnackbar.error(title: 'Error', message: message);
  }
}
