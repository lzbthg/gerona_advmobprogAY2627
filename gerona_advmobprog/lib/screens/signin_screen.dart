import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/user.dart';
import '../providers/cart_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB_ACT4 ENHANCEMENT 2:
// Custom sign-in screen wired to UserService for the actual authentication
// logic (login + persisting the session locally).
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        // loginUser() already persists the session internally, so no need
        // to call saveUserData() again here.
        final response = await _userService.loginUser(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        final user = User.fromJson(response);

        // LAB_ACT4 ENHANCEMENT 3:
        // Point the shared CartProvider at the user who just signed in.
        context.read<CartProvider>().setUserId(user.id);

        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: user,
        );
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
              vertical: 32.h,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40.h),

                  // Logo and welcome message.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/nubdexchange_logo.png',
                        width: 50.w,
                      ),
                      SizedBox(width: 10.w),
                      CustomText(
                        text: 'Welcome',
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Added subtitle.
                  CustomText(
                    text: 'Sign in to continue to NUBD Exchange',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8.h),

                  CustomText(
                    text: 'Enter your username and password to access your account.',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 32.h),

                  _boxedField(
                    label: 'Username',
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16.h),

                  _boxedField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _login();
                      }
                    },
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
                      return null;
                    },
                  ),

                  SizedBox(height: 32.h),

                  SizedBox(
                    height: 52.h,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _login,
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
                          : const Icon(Icons.login),
                      label: CustomText(
                        text: _isLoading ? 'Signing In...' : 'Sign In',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Additional informational text.
                  CustomText(
                    text: 'Welcome back! We are happy to have you with us.',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Boxed field with the label placed above the box.
  Widget _boxedField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: label,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(
                color: AppColors.navy,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
