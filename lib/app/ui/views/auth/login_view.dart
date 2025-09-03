import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth/auth_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  static final TextEditingController _emailController = TextEditingController();
  static final TextEditingController _passwordController = TextEditingController();
  static final RxBool _isPasswordVisible = false.obs;
  static final RxBool _isLoginMode = true.obs;
  static final RxString _emailError = ''.obs;
  static final RxString _passwordError = ''.obs;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Obx(() => Text(
          _isLoginMode.value ? 'Log in or Sign up' : 'Create Account',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        )),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      
                      // Welcome Text
                      Obx(() => Text(
                        _isLoginMode.value ? 'Welcome back' : 'Create your account',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      )),
                      const SizedBox(height: 8),
                      Obx(() => Text(
                        _isLoginMode.value 
                          ? 'Sign in to your account to continue'
                          : 'Join us and start your journey',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      )),
                      
                      const SizedBox(height: 40),
                      
                      // Email Input
                      _buildInputField(
                        controller: _emailController,
                        error: _emailError,
                        label: 'Email',
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Password Input
                      Obx(() => _buildPasswordField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        isVisible: _isPasswordVisible.value,
                        onToggleVisibility: () => _isPasswordVisible.toggle(),
                        error: _passwordError,
                      )),
                      
                      const SizedBox(height: 12),
                      
                      // Forgot Password
                      Obx(() => _isLoginMode.value
                        ? Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Get.snackbar(
                                  'Feature Coming Soon',
                                  'Password reset feature will be available soon.',
                                  backgroundColor: Colors.blue[50],
                                  colorText: Colors.blue[800],
                                  snackPosition: SnackPosition.TOP,
                                );
                              },
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login/Signup Button
                      Obx(() => _buildPrimaryButton(
                        text: _isLoginMode.value ? 'Sign in' : 'Create account',
                        isLoading: authController.isLoading.value,
                        onPressed: () => _handleSubmit(authController),
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Social Login Buttons
                      _buildSocialButton(
                        text: 'Continue with Google',
                        icon: Icons.g_mobiledata,
                        backgroundColor: Colors.white,
                        textColor: Colors.black87,
                        borderColor: Colors.grey[300]!,
                        onPressed: () => _showComingSoon('Google login'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildSocialButton(
                        text: 'Continue with Facebook',
                        icon: Icons.facebook,
                        backgroundColor: const Color(0xFF1877F2),
                        textColor: Colors.white,
                        onPressed: () => _showComingSoon('Facebook login'),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildSocialButton(
                        text: 'Continue with Apple',
                        icon: Icons.apple,
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        onPressed: () => _showComingSoon('Apple login'),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Switch Login/Signup Mode
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Obx(() => Text(
                      _isLoginMode.value
                        ? "Don't have an account? "
                        : "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    )),
                    TextButton(
                      onPressed: () => _isLoginMode.toggle(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Obx(() => Text(
                        _isLoginMode.value ? 'Sign up' : 'Sign in',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      )),
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

  static void _handleSubmit(AuthController authController) {
    // Clear previous errors
    _emailError.value = '';
    _passwordError.value = '';
    
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    bool hasError = false;
    
    // Validate email
    if (email.isEmpty) {
      _emailError.value = 'Email is required';
      hasError = true;
    } else if (!GetUtils.isEmail(email)) {
      _emailError.value = 'Please enter a valid email';
      hasError = true;
    }
    
    // Validate password
    if (password.isEmpty) {
      _passwordError.value = 'Password is required';
      hasError = true;
    } else if (password.length < 6) {
      _passwordError.value = 'Password must be at least 6 characters';
      hasError = true;
    }
    
    if (hasError) return;
    
    if (_isLoginMode.value) {
      authController.login(email: email, password: password);
    } else {
      Get.snackbar(
        'Feature Coming Soon',
        'Sign up feature will be available soon.',
        backgroundColor: Colors.blue[50],
        colorText: Colors.blue[800],
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required RxString error,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error.value.isEmpty ? Colors.grey[200]! : Colors.red,
              width: error.value.isEmpty ? 1 : 2,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            onChanged: (_) => error.value = '',
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        )),
        Obx(() => error.value.isEmpty
            ? const SizedBox(height: 4)
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error.value,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              )
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required RxString error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error.value.isEmpty ? Colors.grey[200]! : Colors.red,
              width: error.value.isEmpty ? 1 : 2,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            onChanged: (_) => error.value = '',
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[600]),
              suffixIcon: IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[600],
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
        Obx(() => error.value.isEmpty
            ? const SizedBox(height: 4)
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  error.value,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              )
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.blue[600]!.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: borderColor != null ? 0 : 1,
          shadowColor: Colors.black.withOpacity(0.1),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    Get.snackbar(
      'Coming Soon',
      '$feature will be available in a future update.',
      backgroundColor: Colors.orange[50],
      colorText: Colors.orange[800],
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }
}
