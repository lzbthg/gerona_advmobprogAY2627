import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/user.dart';
// import '../providers/cart_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB_ACT4 ENHANCEMENT 2:
// Custom sign-in screen wired to UserService for the actual authentication
// logic (login + persisting the session locally).
//
// Enhancement 2 (DummyJSON vs Firebase Auth):
// A LoginType selector lets the user choose which backend to authenticate
// against. DummyJSON logs in against the seeded demo users via
// https://dummyjson.com/auth/login (identifier = username); Firebase Auth
// logs in via the FirebaseAuth SDK (identifier = email).
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final UserService _userService = UserService();

  LoginType _loginType = LoginType.dummyJson;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      try {
        final identifier = _emailController.text.trim();
        final password = _passwordController.text;
        User user;

        if (_loginType == LoginType.dummyJson) {
          // loginUser() already persists the session internally, so no need
          // to call saveUserData() again here.
          final response = await _userService.loginUser(identifier, password);
          user = User.fromJson(response);
        } else {
          // signIn()/UserService caches a local User snapshot internally so
          // Splash/Home/Profile can read a consistent model afterwards.
          await _userService.signIn(email: identifier, password: password);
          user = await _userService.getUser();
        }

        if (!mounted) return;

        // LAB_ACT4 ENHANCEMENT 3:
        // Point the shared CartProvider at the user who just signed in.
        // context.read<CartProvider>().setUserId(user.id);

        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(context, '/home', arguments: user);
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
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
                    color: colorScheme.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8.h),

                  CustomText(
                    text:
                        'Enter your email and password to access your account.',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 24.h),

                  // Enhancement 2 (DummyJSON vs Firebase Auth):
                  // Lets the user pick which backend authenticates them.
                  _loginTypeSelector(),

                  SizedBox(height: 24.h),

                  _boxedField(
                    label: _loginType == LoginType.dummyJson
                        ? 'Username'
                        : 'Email',
                    controller: _emailController,
                    keyboardType: _loginType == LoginType.dummyJson
                        ? TextInputType.text
                        : TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _loginType == LoginType.dummyJson
                            ? 'Please enter your username'
                            : 'Please enter your email';
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        text: 'Don\'t have an account? ',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: CustomText(
                          text: 'Sign up here',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Additional informational text.
                  CustomText(
                    text: 'Welcome back! We are happy to have you with us.',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
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

  // Enhancement 2 (DummyJSON vs Firebase Auth):
  // Simple segmented selector so the user can pick which backend Sign In
  // authenticates against.
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

  // Boxed field with the label placed above the box.
  Widget _boxedField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
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
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
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