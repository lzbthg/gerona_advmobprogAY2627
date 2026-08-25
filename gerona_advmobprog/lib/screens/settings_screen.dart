import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Card(
              child: SwitchListTile(
                // ENHANCEMENT 3: Dark/light mode switch has been moved to the Settings page.
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
                  // ENHANCEMENT 3: Changes the application theme.
                  themeProvider.toggleTheme();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
