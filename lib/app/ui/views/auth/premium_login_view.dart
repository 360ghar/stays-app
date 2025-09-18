import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../controllers/auth/auth_controller.dart';
import '../../theme/theme_extensions.dart';

class PremiumLoginView extends StatefulWidget {
  const PremiumLoginView({super.key});

  @override
  State<PremiumLoginView> createState() => _PremiumLoginViewState();
}

class _PremiumLoginViewState extends State<PremiumLoginView>
    with TickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoginMode = true.obs;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final isDark = context.isDark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    final gradientColors = [
      colors.primary,
      colors.secondary,
      colors.tertiary ?? colors.primaryContainer,
    ];

    final glassTint = Colors.white.withValues(alpha: isDark ? 0.12 : 0.2);
    final glassBorder = Colors.white.withValues(alpha: isDark ? 0.18 : 0.32);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: isDark ? 0.1 : 0.15),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.95),
                                Colors.white.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.onSurface.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.apartment_rounded,
                            size: 50,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Obx(
                        () => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            isLoginMode.value
                                ? 'Welcome Back'
                                : 'Create Account',
                            key: ValueKey(isLoginMode.value),
                            style: textStyles.headlineMedium?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: const [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black26,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(
                        () => Text(
                          isLoginMode.value
                              ? 'Sign in to continue your journey'
                              : 'Join us and explore amazing stays',
                          style: textStyles.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: glassTint,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: glassBorder, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                _buildGlassTextField(
                                  controller: emailController,
                                  hint: 'Email address',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                Obx(
                                  () => _buildGlassTextField(
                                    controller: passwordController,
                                    hint: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: !isPasswordVisible.value,
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          isPasswordVisible.toggle(),
                                      icon: Icon(
                                        isPasswordVisible.value
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Obx(
                                  () => _buildGradientButton(
                                    text: isLoginMode.value
                                        ? 'Sign In'
                                        : 'Create Account',
                                    isLoading: authController.isLoading.value,
                                    onPressed: _handleAuth,
                                    colors: colors,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Obx(
                                  () => isLoginMode.value
                                      ? TextButton(
                                          onPressed: () =>
                                              _showComingSoon('Password reset'),
                                          child: Text(
                                            'Forgot your password?',
                                            style: textStyles.bodySmall?.copyWith(
                                              color:
                                                  Colors.white.withValues(alpha: 0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or continue with',
                              style: textStyles.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            icon: Icons.g_mobiledata_rounded,
                            onPressed: () => _showComingSoon('Google login'),
                            colors: colors,
                            glassTint: glassTint,
                            glassBorder: glassBorder,
                          ),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                            icon: Icons.facebook_rounded,
                            onPressed: () => _showComingSoon('Facebook login'),
                            colors: colors,
                            glassTint: glassTint,
                            glassBorder: glassBorder,
                          ),
                          const SizedBox(width: 16),
                          _buildSocialButton(
                            icon: Icons.apple_rounded,
                            onPressed: () => _showComingSoon('Apple login'),
                            colors: colors,
                            glassTint: glassTint,
                            glassBorder: glassBorder,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Obx(
                            () => Text(
                              isLoginMode.value
                                  ? "Don't have an account? "
                                  : "Already have an account? ",
                              style: textStyles.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              isLoginMode.toggle();
                              _scaleController
                                ..reset()
                                ..forward();
                            },
                            child: Obx(
                              () => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.only(bottom: 2),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  isLoginMode.value ? 'Sign up' : 'Sign in',
                                  style: textStyles.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
    required ColorScheme colors,
  }) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.reverse(),
      onTapUp: (_) {
        _scaleController.forward();
        if (!isLoading) onPressed();
      },
      onTapCancel: () => _scaleController.forward(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.secondary, colors.primary],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colors,
    required Color glassTint,
    required Color glassBorder,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: glassTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: glassBorder, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAuth() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      final colors = context.colors;
      Get.snackbar(
        'Oops!',
        'Please fill in all fields',
        snackPosition: SnackPosition.TOP,
        backgroundColor: colors.errorContainer.withValues(alpha: 0.9),
        colorText: colors.onErrorContainer,
        borderRadius: 16,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 500),
      );
      return;
    }

    if (isLoginMode.value) {
      authController.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } else {
      _showComingSoon('Sign up feature');
    }
  }

  void _showComingSoon(String feature) {
    final colors = context.colors;
    Get.snackbar(
      'Coming Soon!',
      '$feature will be available soon',
      snackPosition: SnackPosition.TOP,
      backgroundColor: colors.secondaryContainer.withValues(alpha: 0.9),
      colorText: colors.onSecondaryContainer,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      animationDuration: const Duration(milliseconds: 500),
    );
  }
}
