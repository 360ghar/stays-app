import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/auth/phone_auth_controller.dart';

class StaticPhoneLoginView extends StatefulWidget {
  const StaticPhoneLoginView({super.key});

  @override
  State<StaticPhoneLoginView> createState() => _StaticPhoneLoginViewState();
}

class _StaticPhoneLoginViewState extends State<StaticPhoneLoginView>
    with SingleTickerProviderStateMixin {
  late final PhoneAuthController controller;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoginMode = true.obs;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PhoneAuthController>();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: double.infinity,
                height: constraints.maxHeight,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 64 : 24,
                  vertical: isSmallScreen ? 16 : 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top section - Logo and Title
                    Flexible(
                      flex: isSmallScreen ? 2 : 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: isSmallScreen ? 50 : 60,
                            height: isSmallScreen ? 50 : 60,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.home_rounded,
                              size: isSmallScreen ? 24 : 30,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          
                          // Title
                          Obx(() => Text(
                            isLoginMode.value ? 'Log in or Sign up' : 'Create account',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                          )),
                          
                          SizedBox(height: isSmallScreen ? 4 : 6),
                          
                          Obx(() => Text(
                            isLoginMode.value 
                              ? 'Welcome back!' 
                              : 'Join us today',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          )),
                        ],
                      ),
                    ),
                    
                    // Middle section - Form
                    Flexible(
                      flex: isSmallScreen ? 4 : 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Phone field
                          _buildPhoneField(isSmallScreen),
                          
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          
                          // Password field
                          Obx(() => _buildPasswordField(isSmallScreen)),
                          
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          
                          // Forgot password
                          Obx(() => isLoginMode.value
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showComingSoon('Password reset'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size(50, isSmallScreen ? 24 : 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontSize: isSmallScreen ? 12 : 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          
                          // Continue button
                          Obx(() => _buildPrimaryButton(isSmallScreen)),
                          
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          
                          // Divider
                          _buildDivider(isSmallScreen),
                          
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          
                          // Social buttons - Compact layout
                          _buildSocialButtons(isSmallScreen),
                        ],
                      ),
                    ),
                    
                    // Bottom section - Footer
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Obx(() => Text(
                                isLoginMode.value 
                                  ? "Don't have an account? " 
                                  : "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              )),
                              GestureDetector(
                                onTap: () => isLoginMode.toggle(),
                                child: Obx(() => Text(
                                  isLoginMode.value ? 'Sign up' : 'Log in',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.blue.shade600,
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 44 : 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 14),
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: Colors.grey.shade600,
                  size: isSmallScreen ? 16 : 18,
                ),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  '+91',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: isSmallScreen ? 20 : 24,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Phone number',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 44 : 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: passwordController,
        obscureText: !isPasswordVisible.value,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade600,
            size: isSmallScreen ? 16 : 18,
          ),
          suffixIcon: IconButton(
            onPressed: () => isPasswordVisible.toggle(),
            icon: Icon(
              isPasswordVisible.value 
                ? Icons.visibility_off_outlined 
                : Icons.visibility_outlined,
              color: Colors.grey.shade600,
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 14,
            vertical: isSmallScreen ? 12 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 44 : 50,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBackgroundColor: Colors.blue.shade300,
        ),
        child: controller.isLoading.value
          ? SizedBox(
              width: isSmallScreen ? 18 : 20,
              height: isSmallScreen ? 18 : 20,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              isLoginMode.value ? 'Continue' : 'Create account',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
      ),
    );
  }

  Widget _buildDivider(bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(bool isSmallScreen) {
    return Column(
      children: [
        _buildSocialButton(
          icon: 'G',
          text: 'Continue with Google',
          onPressed: () => _showComingSoon('Google login'),
          backgroundColor: Colors.white,
          textColor: const Color(0xFF1A1A1A),
          borderColor: Colors.grey.shade300,
          isSmallScreen: isSmallScreen,
        ),
        
        SizedBox(height: isSmallScreen ? 8 : 10),
        
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                icon: 'f',
                text: 'Facebook',
                onPressed: () => _showComingSoon('Facebook login'),
                backgroundColor: const Color(0xFF1877F2),
                textColor: Colors.white,
                isSmallScreen: isSmallScreen,
                isCompact: true,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Expanded(
              child: _buildSocialButton(
                icon: '',
                text: 'Apple',
                onPressed: () => _showComingSoon('Apple login'),
                backgroundColor: Colors.black,
                textColor: Colors.white,
                useAppleIcon: true,
                isSmallScreen: isSmallScreen,
                isCompact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    bool useAppleIcon = false,
    required bool isSmallScreen,
    bool isCompact = false,
  }) {
    return SizedBox(
      height: isSmallScreen ? 40 : 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          side: BorderSide(
            color: borderColor ?? backgroundColor,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (useAppleIcon)
              Icon(Icons.apple, size: isSmallScreen ? 16 : 18)
            else if (icon.isNotEmpty)
              Text(
                icon,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: icon == 'G' ? Colors.blue : textColor,
                ),
              ),
            SizedBox(width: isCompact ? 6 : 10),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() {
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter both phone number and password',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (phone.length != 10) {
      Get.snackbar(
        'Invalid Phone',
        'Please enter a valid 10-digit phone number',
        backgroundColor: Colors.orange.shade50,
        colorText: Colors.orange.shade800,
        snackPosition: SnackPosition.TOP,
        borderRadius: 8,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (isLoginMode.value) {
      controller.loginWithPhone(
        phone: phone,
        password: password,
      );
    } else {
      _showComingSoon('Sign up');
    }
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Coming Soon',
      '$feature will be available soon',
      backgroundColor: Colors.blue.shade50,
      colorText: Colors.blue.shade800,
      snackPosition: SnackPosition.TOP,
      borderRadius: 8,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }
}