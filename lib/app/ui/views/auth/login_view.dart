import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../theme/theme_extensions.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isLoginMode = true;
  String _emailError = '';
  String _passwordError = '';
  bool _isLoading = false;

  late final AuthController authController;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();

    ever(authController.isLoading, (loading) {
      if (mounted) {
        setState(() => _isLoading = loading);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
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
        title: Text(
          _isLoginMode ? 'Log in or Sign up' : 'Create Account',
          style: textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        _isLoginMode ? 'Welcome back' : 'Create your account',
                        style: textStyles.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoginMode
                            ? 'Sign in to your account to continue'
                            : 'Join us and start your journey',
                        style: textStyles.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildInputField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        label: 'Email',
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        error: _emailError,
                        onChanged: (value) {
                          if (_emailError.isNotEmpty) {
                            setState(() => _emailError = '');
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        label: 'Password',
                        hint: 'Enter your password',
                        isVisible: _isPasswordVisible,
                        onToggleVisibility: () {
                          setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          );
                        },
                        error: _passwordError,
                        onChanged: (value) {
                          if (_passwordError.isNotEmpty) {
                            setState(() => _passwordError = '');
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_isLoginMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember-me checkbox mirrors controller state via Obx.
                            Obx(() {
                              final isChecked = authController.rememberMe.value;
                              return InkWell(
                                onTap: () =>
                                    authController.setRememberMe(!isChecked),
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isChecked,
                                      onChanged: (value) => authController
                                          .setRememberMe(value ?? false),
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
                              onPressed: () {
                                Get.snackbar(
                                  'Feature coming soon',
                                  'Password reset will be available shortly.',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: colors.primaryContainer
                                      .withValues(alpha: 0.9),
                                  colorText: colors.onPrimaryContainer,
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: colors.primary,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: textStyles.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _buildPrimaryButton(
                        text: _isLoginMode ? 'Sign in' : 'Create account',
                        isLoading: _isLoading,
                        onPressed: _handleSubmit,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: textStyles.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSocialButton(
                        text: 'Continue with Google',
                        icon: Icons.g_mobiledata,
                        backgroundColor: colors.surface,
                        foregroundColor: colors.onSurface,
                        borderColor: colors.outlineVariant,
                        onPressed: () => _showComingSoon('Google login'),
                      ),
                      const SizedBox(height: 12),
                      _buildSocialButton(
                        text: 'Continue with Facebook',
                        icon: Icons.facebook,
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        onPressed: () => _showComingSoon('Facebook login'),
                      ),
                      const SizedBox(height: 12),
                      _buildSocialButton(
                        text: 'Continue with Apple',
                        icon: Icons.apple,
                        backgroundColor: colors.onSurface,
                        foregroundColor: colors.surface,
                        onPressed: () => _showComingSoon('Apple login'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLoginMode
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: textStyles.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _emailError = '';
                          _passwordError = '';
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(_isLoginMode ? 'Sign up' : 'Sign in'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    FocusScope.of(context).unfocus();

    setState(() {
      _emailError = '';
      _passwordError = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    var hasError = false;

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!GetUtils.isEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      hasError = true;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      hasError = true;
    }

    if (hasError) return;

    if (_isLoginMode) {
      authController.login(email: email, password: password);
    } else {
      final colors = context.colors;
      Get.snackbar(
        'Feature coming soon',
        'Sign up will be available shortly.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.primaryContainer.withValues(alpha: 0.9),
        colorText: colors.onPrimaryContainer,
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String error,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final labelStyle = textStyles.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.onSurface,
    );
    final fieldStyle =
        textStyles.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.elevatedSurface(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error.isEmpty ? colors.outlineVariant : colors.error,
              width: error.isEmpty ? 1 : 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: fieldStyle,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: fieldStyle.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error,
              style:
                  textStyles.bodySmall?.copyWith(color: colors.error) ??
                  TextStyle(color: colors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String error,
    required Function(String) onChanged,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    final labelStyle = textStyles.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: colors.onSurface,
    );
    final fieldStyle =
        textStyles.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        ) ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: colors.onSurface,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: context.elevatedSurface(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error.isEmpty ? colors.outlineVariant : colors.error,
              width: error.isEmpty ? 1 : 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !isVisible,
            style: fieldStyle,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: fieldStyle.copyWith(
                color: colors.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              suffixIcon: IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error,
              style:
                  textStyles.bodySmall?.copyWith(color: colors.error) ??
                  TextStyle(color: colors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 2,
          shadowColor: colors.primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.onPrimary),
                ),
              )
            : Text(
                text,
                style:
                    textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimary,
                    ) ??
                    TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onPrimary,
                    ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    final textStyles = context.textStyles;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: borderColor != null ? 0 : 1,
          shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style:
                  textStyles.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                  ) ??
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    final colors = context.colors;
    Get.snackbar(
      'Coming soon',
      '$feature will be available in a future update.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: colors.secondaryContainer.withValues(alpha: 0.9),
      colorText: colors.onSecondaryContainer,
      duration: const Duration(seconds: 2),
    );
  }
}
