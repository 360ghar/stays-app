import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:stays_app/features/auth/controllers/auth_controller.dart';
import 'package:stays_app/features/auth/controllers/form_validation_controller.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/utils/services/token_service.dart';
import 'package:stays_app/app/utils/services/validation_service.dart';
 
 @GenerateMocks([AuthRepository, TokenService])
 import 'auth_controller_test.mocks.dart';
 
 void main() {
 
   setUp(() {
     Get.testMode = true;
     Get.reset();
   });
 
   tearDown(() {
     Get.reset();
   });
 
  group('AuthController initialization', () {
    late MockAuthRepository mockAuthRepository;
    late MockTokenService mockTokenService;
    late AuthController authController;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockTokenService = MockTokenService();
      
      when(mockTokenService.ready).thenAnswer((_) async {});
      when(mockTokenService.isAuthenticated).thenReturn(false.obs);
      when(mockTokenService.clearTokens()).thenAnswer((_) async {});
      
      Get.put<ValidationService>(ValidationService());
      Get.put<FormValidationController>(FormValidationController());
      
      authController = AuthController(
        authRepository: mockAuthRepository,
        tokenService: mockTokenService,
      );
    });

     test('should initialize with unauthenticated state', () {
       expect(authController.isAuthenticated.value, false);
       expect(authController.currentUser.value, null);
     });
 
     test('should have password visibility off by default', () {
       expect(authController.isPasswordVisible.value, false);
     });
 
     test('should toggle password visibility', () {
       expect(authController.isPasswordVisible.value, false);
       
       authController.togglePasswordVisibility();
       expect(authController.isPasswordVisible.value, true);
       
       authController.togglePasswordVisibility();
       expect(authController.isPasswordVisible.value, false);
     });
   });
 
  group('FormValidationController', () {
    late FormValidationController validationController;
    
    setUp(() {
      Get.put<ValidationService>(ValidationService());
      validationController = Get.put<FormValidationController>(FormValidationController());
    });
    
    test('should validate email format correctly', () {
      final result = validationController.validateEmailOrPhone('test@example.com');
      expect(result, isNull);
    });
    
    test('should reject invalid email format', () {
      final result = validationController.validateEmailOrPhone('invalid-email');
      expect(result, isNotNull);
    });
    
    test('should validate phone format correctly', () {
      final result = validationController.validateEmailOrPhone('9876543210');
      expect(result, isNull);
    });
    
    test('should validate password length', () {
      final shortPassword = validationController.validatePassword('123');
      expect(shortPassword, isNotNull);
      
      final validPassword = validationController.validatePassword('password123');
      expect(validPassword, isNull);
    });
    
    test('should validate confirm password matches', () {
      final mismatch = validationController.validateConfirmPassword('pass1', 'pass2');
      expect(mismatch, isNotNull);
      
      final match = validationController.validateConfirmPassword('password', 'password');
      expect(match, isNull);
    });
    
    test('should clear all errors', () {
      validationController.emailOrPhoneError.value = 'Error';
      validationController.passwordError.value = 'Error';
      validationController.confirmPasswordError.value = 'Error';
      
      validationController.clearErrors();
      
      expect(validationController.emailOrPhoneError.value, isEmpty);
      expect(validationController.passwordError.value, isEmpty);
      expect(validationController.confirmPasswordError.value, isEmpty);
    });
   });
 }
