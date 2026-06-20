import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stays_app/app/data/repositories/auth_repository.dart';
import 'package:stays_app/app/routes/app_routes.dart';
import 'package:stays_app/app/utils/helpers/app_snackbar.dart';
import 'package:stays_app/features/auth/controllers/auth_controller.dart';

/// Profile completion screen shown when the backend gate evaluation returns
/// `stage: profile_completion`. Collects mandatory fields (full_name,
/// date_of_birth) and updates the profile before routing to the app.
class ProfileCompletionView extends StatefulWidget {
  const ProfileCompletionView({super.key});

  @override
  State<ProfileCompletionView> createState() => _ProfileCompletionViewState();
}

class _ProfileCompletionViewState extends State<ProfileCompletionView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    if (user != null) {
      _nameController.text = user.name ?? user.firstName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      AppSnackbar.error(
        title: 'Required',
        message: 'Please select your date of birth',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authController = Get.find<AuthController>();
      await authController.updateUserProfileData(
        fullName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth,
      );

      // Re-evaluate gate — the backend is the single source of truth.
      // Navigate based on the gate response to handle the case where the
      // user transitions to app_onboarding or active after profile completion.
      final authRepository = Get.find<AuthRepository>();
      try {
        final gateState = await authRepository.getAuthGateState(app: 'stays');
        final stage = gateState['stage'] as String? ?? 'active';
        // Loop prevention: if the backend still returns profile_completion
        // after a successful update (backend bug or data not saved), break
        // the loop by going to home.
        switch (stage) {
          case 'profile_completion':
            Get.offAllNamed(Routes.home);
            break;
          case 'app_onboarding':
            Get.offAllNamed(Routes.onboarding);
            break;
          case 'active':
          default:
            Get.offAllNamed(Routes.home);
        }
      } catch (_) {
        // If gate fails, default to home.
        Get.offAllNamed(Routes.home);
      }
    } catch (e) {
      AppSnackbar.error(
        title: 'Error',
        message: 'Failed to update profile: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'We need a few more details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide your full name and date of birth to continue.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date of Birth
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : 'Select your date of birth',
                      style: TextStyle(
                        color: _dateOfBirth != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
