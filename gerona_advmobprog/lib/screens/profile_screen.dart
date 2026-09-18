import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB_ACT4 ENHANCEMENT 3:
// Custom profile screen that renders the signed-in user's data (via
// UserService/User model).
class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/signin',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: CustomText(
          text: user.firstName.isNotEmpty ? user.firstName : user.username,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 24.sp, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            _profileCard(user),
            SizedBox(height: 20.h),
            _infoCard(user),
            SizedBox(height: 20.h),
            SizedBox(
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.logoutRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: Text(
                  'Log Out',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(User user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48.r,
            backgroundColor: AppColors.lightBg,
            backgroundImage: user.image.isNotEmpty
                ? NetworkImage(user.image)
                : null,
            child: user.image.isEmpty
                ? Icon(Icons.person, size: 48.sp, color: AppColors.navy)
                : null,
          ),
          SizedBox(height: 12.h),
          CustomText(
            text: user.fullName.isNotEmpty ? user.fullName : user.username,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
          SizedBox(height: 4.h),
          CustomText(
            text: '@${user.username}',
            fontSize: 13.sp,
            color: AppColors.navy,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(User user) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, 'Email', user.email),
          Divider(height: 20.h),
          _infoRow(Icons.wc_outlined, 'Gender', user.gender),
          Divider(height: 20.h),
          _infoRow(Icons.badge_outlined, 'User ID', '${user.id}'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.gold),
        SizedBox(width: 12.w),
        CustomText(text: label, fontSize: 13.sp),
        const Spacer(),
        CustomText(
          text: value.isNotEmpty ? value : '—',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}
