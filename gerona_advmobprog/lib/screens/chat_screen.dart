import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

// Lab Activity 6 (Firebase Part II):
// Lists every registered Firebase user from Firestore's "Users" collection
// (Enhancement 1: excluding the signed-in user), with a search bar to filter
// by name or email (Enhancement 2). Tapping a user opens a 1:1 conversation.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentUserEmail = userService.value.currentUser?.email;
    final currentUid = userService.value.currentUser?.uid;

    // DummyJSON demo sessions have no Firebase identity, so there is no
    // real chat account to send/receive messages as.
    if (currentUid == null || currentUid.isEmpty) {
      return _gate(
        'Chat is only available for Firebase accounts. Sign in with '
        'Firebase to message other registered users.',
      );
    }

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 12.h),

          // Enhancement 2: search bar to filter users by name or email.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() => _searchText = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _message('Error loading users.');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _message('No registered users found yet.');
                }

                // Enhancement 1: exclude the current logged-in user.
                var users = snapshot.data!
                    .where((user) => (user['uid'] ?? '') != currentUid)
                    .toList();

                // Enhancement 2: filter by name or email.
                if (_searchText.isNotEmpty) {
                  users = users.where((user) {
                    final firstName =
                        (user['firstName'] ?? '').toString().toLowerCase();
                    final lastName =
                        (user['lastName'] ?? '').toString().toLowerCase();
                    final username =
                        (user['username'] ?? '').toString().toLowerCase();
                    final email = (user['email'] ?? '').toString().toLowerCase();
                    return firstName.contains(_searchText) ||
                        lastName.contains(_searchText) ||
                        username.contains(_searchText) ||
                        email.contains(_searchText);
                  }).toList();
                }

                if (users.isEmpty) {
                  return _message('No users match your search.');
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final firstName = (user['firstName'] ?? '').toString();
                    final displayName = firstName.isNotEmpty
                        ? firstName
                        : (user['email'] ?? 'Unknown').toString();
                    final initial =
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

                    return Card(
                      margin: EdgeInsets.only(bottom: 10.h),
                      elevation: 0,
                      color: colors.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        leading: CircleAvatar(
                          radius: 22.r,
                          backgroundColor: AppColors.navy,
                          child: CustomText(
                            text: initial,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        title: CustomText(
                          text: displayName,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        subtitle: CustomText(
                          text: (user['email'] ?? 'No email').toString(),
                          fontSize: 12.sp,
                          color: colors.onSurfaceVariant,
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: colors.onSurfaceVariant,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                currentUserEmail: currentUserEmail ?? '',
                                tappedUser: user,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _gate(String message) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_outlined,
                size: 48.sp, color: colors.onSurfaceVariant),
            SizedBox(height: 12.h),
            CustomText(
              text: message,
              fontSize: 13.sp,
              color: colors.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: CustomText(
        text: text,
        fontSize: 14.sp,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}
