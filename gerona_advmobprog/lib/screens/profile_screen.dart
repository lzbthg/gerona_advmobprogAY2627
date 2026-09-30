import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// LAB_ACT4 ENHANCEMENT 3:
// Custom profile screen that renders the signed-in user's data (via
// UserService/User model), and lets the user manage their account: update
// username, change password, delete account, and log out. Account
// management actions branch on the user's LoginType — Firebase-authenticated
// sessions call the real FirebaseAuth APIs, while DummyJSON demo sessions
// are simulated locally (DummyJSON's public API doesn't persist writes).
class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late User _currentUser;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _refreshUser();
  }

  bool get _isDummyAccount => _currentUser.loginType == LoginType.dummyJson;

  Future<void> _refreshUser() async {
    final refreshed = await _userService.getUser();
    if (!mounted) return;
    setState(() {
      _currentUser = refreshed;
    });
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Enhancement 3: update username, routed through UserService which
  // branches internally on the account's LoginType.
  Future<void> _showUpdateUsernameDialog() async {
    final controller = TextEditingController(text: _currentUser.username);
    final formKey = GlobalKey<FormState>();

    final newUsername = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Username'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a username';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newUsername == null || newUsername == _currentUser.username) return;

    setState(() => _isProcessing = true);
    try {
      await _userService.updateUsername(username: newUsername);
      await _refreshUser();
      _showSnack(
        _isDummyAccount
            ? 'Username updated locally (demo account; not persisted to DummyJSON).'
            : 'Username updated successfully.',
      );
    } catch (e) {
      _showSnack('Failed to update username: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Enhancement 3: change password, routed through UserService which
  // branches internally on the account's LoginType.
  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        email: _currentUser.email,
      );
      _showSnack(
        _isDummyAccount
            ? 'Password change simulated (demo account; DummyJSON has no real password store).'
            : 'Password updated successfully.',
      );
    } catch (e) {
      _showSnack('Failed to update password: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Enhancement 3: delete account, routed through UserService which
  // branches internally on the account's LoginType.
  Future<void> _showDeleteAccountDialog() async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account. Enter your '
                'password to confirm.',
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.logoutRed),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await _userService.deleteAccount(
        email: _currentUser.email,
        password: passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (e) {
      _showSnack('Failed to delete account: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        // Brand navy, matching the shared AppBar on Home/Products/Cart/Chat
        // (see AppColors.navy in constants.dart) instead of the
        // theme-generated colorScheme.primary blue.
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: CustomText(
          text: user.fullName.isNotEmpty ? user.fullName : user.username,
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
        child: AbsorbPointer(
          absorbing: _isProcessing,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            children: [
              _profileCard(user),
              SizedBox(height: 20.h),
              _infoCard(user),
              SizedBox(height: 20.h),
              _accountActionsCard(),
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
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileCard(User user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48.r,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: user.image.isNotEmpty
                ? NetworkImage(user.image)
                : null,
            child: user.image.isEmpty
                ? Icon(
                    Icons.person,
                    size: 48.sp,
                    color: colorScheme.onSurfaceVariant,
                  )
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
            color: colorScheme.primary,
          ),

          SizedBox(height: 8.h),

          Chip(
            label: CustomText(
              text: user.loginType == LoginType.dummyJson
                  ? 'DummyJSON Account'
                  : 'Firebase Account',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            ),
            backgroundColor: colorScheme.secondaryContainer,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _infoCard(User user) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.email_outlined, 'Email', user.email),
          Divider(height: 20.h, color: colorScheme.outlineVariant),

          _infoRow(Icons.wc_outlined, 'Gender', user.gender),
          Divider(height: 20.h, color: colorScheme.outlineVariant),

          if (user.id > 0)
            _infoRow(Icons.badge_outlined, 'User ID', '${user.id}'),

          if (user.age > 0) ...[
            Divider(height: 20.h, color: colorScheme.outlineVariant),
            _infoRow(Icons.cake_outlined, 'Age', user.age > 0 ? '${user.age}' : '',
            ),

            Divider(height: 20.h, color: colorScheme.outlineVariant),
            _infoRow(Icons.call_outlined, 'Contact No.', user.contactNo),
          ],
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

  // Enhancement 3: account management actions (update username, change
  // password, delete account).
  Widget _accountActionsCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      elevation: 2,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.edit_outlined, color: colorScheme.primary),
            title: Text(
              'Update Username',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: _isProcessing ? null : _showUpdateUsernameDialog,
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          ListTile(
            leading: Icon(Icons.lock_outline, color: colorScheme.primary),
            title: Text(
              'Change Password',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: _isProcessing ? null : _showChangePasswordDialog,
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.logoutRed),
            title: Text(
              'Delete Account',
              style: TextStyle(color: AppColors.logoutRed),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: _isProcessing ? null : _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}
