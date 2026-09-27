import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// Enhancement 2 (DummyJSON vs Firebase Auth):
// A LoginType selector lets the user choose which backend Sign Up creates
// the account against. DummyJSON posts to the mock
// https://dummyjson.com/users/add endpoint (demo-only, doesn't persist
// real credentials); Firebase creates a real FirebaseAuth account.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final UserService _userService = UserService();

  LoginType _loginType = LoginType.dummyJson;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactNoController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final firstName = _fNameController.text.trim();
      final lastName = _lNameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 0;
      final contactNo = _contactNoController.text.trim();
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      String successMessage;

      if (_loginType == LoginType.dummyJson) {
        // Enhancement 2: DummyJSON's mock /users/add endpoint doesn't
        // persist real credentials, so this is a simulated demo account.
        await _userService.registerDummyUser(
          firstName: firstName,
          lastName: lastName,
          age: age,
          contactNo: contactNo,
          username: username,
          email: email,
          password: password,
        );
        successMessage =
            'Demo account created via DummyJSON. Note: DummyJSON does not '
            'persist new accounts, so sign in with one of its seeded demo '
            'users instead.';
      } else {
        await _userService.createAccount(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          age: age,
          contactNo: contactNo,
        );

        if (!mounted) return;

        if (username.isNotEmpty) {
          await _userService.updateUsername(username: username);
        }

        successMessage = 'Account created successfully. Please sign in.';
      }

      messenger?.showSnackBar(SnackBar(content: Text(successMessage)));

      if (!mounted) return;
      navigator.pushReplacementNamed('/signin');
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/nubdexchange_logo.png',
                        width: 52.w,
                      ),
                      SizedBox(width: 10.w),
                      CustomText(
                        text: 'Create Account',
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  CustomText(
                    text: 'Sign up to start shopping with NUBD Exchange',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20.h),

                  // Enhancement 2 (DummyJSON vs Firebase Auth):
                  // Lets the user pick which backend Sign Up creates the
                  // account against.
                  _loginTypeSelector(),

                  SizedBox(height: 20.h),
                  _boxedField(
                    label: 'First Name',
                    controller: _fNameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _boxedField(
                    label: 'Last Name',
                    controller: _lNameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _boxedField(
                    label: 'Age',
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your age';
                      }

                      final age = int.tryParse(value.trim());

                      if (age == null) {
                        return 'Please enter a valid age';
                      }

                      if (age <= 0) {
                        return 'Age must be greater than 0';
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _boxedField(
                    label: 'Contact Number',
                    controller: _contactNoController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your contact number';
                      }

                      if (!RegExp(r'^[0-9+\-\s]+$').hasMatch(value.trim())) {
                        return 'Please enter a valid contact number';
                      }

                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _boxedField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _boxedField(
                    label: 'Username',
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _boxedField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _boxedField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _signup();
                      }
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 30.h),
                  SizedBox(
                    height: 52.h,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _signup,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      icon: _isLoading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: CustomText(
                        text: _isLoading
                            ? 'Creating Account...'
                            : 'Create Account',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        text: 'Already have an account? ',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: CustomText(
                          text: 'Log in here',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhancement 2 (DummyJSON vs Firebase Auth):
  // Simple segmented selector so the user can pick which backend Sign Up
  // creates the account against.
  Widget _loginTypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: LoginType.values.map((type) {
        final isSelected = _loginType == type;
        final label = type == LoginType.dummyJson ? 'DummyJSON' : 'Firebase';

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: ChoiceChip(
              label: CustomText(
                text: label,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.navy,
              ),
              selected: isSelected,
              selectedColor: AppColors.navy,
              backgroundColor: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
                side: BorderSide(color: AppColors.navy),
              ),
              onSelected: (_) {
                setState(() {
                  _loginType = type;
                });
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _boxedField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: label, fontSize: 12.sp, fontWeight: FontWeight.w600),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: AppColors.navy, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}