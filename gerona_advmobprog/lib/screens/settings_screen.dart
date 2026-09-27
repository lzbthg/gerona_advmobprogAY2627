import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Enhancement 1: Logout button that clears the session/token and
  // redirects back to the Sign In screen.
  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Card(
                child: SwitchListTile(
                  // LAB_ACT2 ENHANCEMENT 3: 
                  // Dark/light mode switch has been moved to the Settings page.
                  title: CustomText(
                    text: 'Dark Mode',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  subtitle: CustomText(
                    text: themeProvider.isDark
                        ? 'Dark mode is enabled'
                        : 'Light mode is enabled',
                    fontSize: 13.sp,
                  ),
                  secondary: Icon(
                    themeProvider.isDark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  value: themeProvider.isDark,
                  onChanged: (value) {
                    // LAB_ACT2 ENHANCEMENT 3: 
                    // Changes the application theme.
                    themeProvider.toggleTheme();
                  },
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: AppColors.logoutRed),
              title: CustomText(
                text: 'Log Out',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.logoutRed,
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
