import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/chat_service.dart';
import '../widgets/custom_text.dart';

// Lab Activity 6 (Firebase Part II) — Enhancement 3:
// Redesigned 1:1 chat screen: clearer sender/receiver bubbles, a fade+slide
// entrance animation per message, and a live sending/sent indicator.
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  bool _isSending = false;
  bool _markingSeen = false;
  Set<String>? _incomingMessageIds;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _receiverId => (widget.tappedUser['uid'] ?? '').toString();

  Future<void> _markIncomingMessagesSeen() async {
    if (_markingSeen || _currentUserId.isEmpty || _receiverId.isEmpty) return;
    _markingSeen = true;
    try {
      await _chatService.markMessagesAsSeen(_currentUserId, _receiverId);
    } catch (_) {
      // Keep the conversation usable if read-receipt writes are unavailable.
    } finally {
      _markingSeen = false;
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending || _receiverId.isEmpty) return;

    setState(() => _isSending = true);
    _msgCtrl.clear();

    try {
      await _chatService.sendMessage(_receiverId, text);
      _msgFocus.requestFocus();
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserName =
        (widget.tappedUser['firstName']?.toString().isNotEmpty == true
                ? widget.tappedUser['firstName']
                : widget.tappedUser['email'] ?? 'Chat')
            .toString();

    if (_currentUserId.isEmpty || _receiverId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Unable to open this chat.')),
      );
    }

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: colors.primaryContainer,
              child: Text(
                tappedUserName.isNotEmpty ? tappedUserName[0].toUpperCase() : '?',
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: tappedUserName,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                  Text(
                    'Conversation',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(_currentUserId, _receiverId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: CustomText(
                      text: 'Error loading messages: ${snapshot.error}',
                      fontSize: 13.sp,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final incomingMessageIds = docs
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['senderId'] ?? '') != _currentUserId;
                    })
                    .map((doc) => doc.id)
                    .toSet();
                final previousIncomingMessageIds = _incomingMessageIds;
                if (previousIncomingMessageIds == null ||
                    !incomingMessageIds.every(
                      previousIncomingMessageIds.contains,
                    )) {
                  _incomingMessageIds = incomingMessageIds;
                  _markIncomingMessagesSeen();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: CustomText(
                      text: 'Say hello to ${tappedUserName.split(' ').first}!',
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = (data['senderId'] ?? '') == _currentUserId;
                    final isPending = isMe && doc.metadata.hasPendingWrites;

                    return _AnimatedBubble(
                      key: ValueKey(doc.id),
                      text: (data['message'] ?? '').toString(),
                      isMe: isMe,
                      isPending: isPending,
                      isSeen: data['isSeen'] == true,
                    );
                  },
                );
              },
            ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _composer() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _msgFocus,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    filled: true,     
                    fillColor: colors.surfaceContainerHighest,
                    hintStyle: TextStyle(color: colors.onSurfaceVariant),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Material(
                color: colors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _isSending ? null : _send,
                  child: SizedBox(
                    width: 46.w,
                    height: 46.w,
                    child: Center(
                      child: _isSending
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: colors.onPrimary,
                              size: 20.sp,
                            ),
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
}

// Enhancement 3: fade + slide entrance for each bubble (keyed by Firestore
// doc id, so it only plays once per message, not on every rebuild), plus an
// AnimatedSwitcher between a "sending" clock icon and a "sent" checkmark.
class _AnimatedBubble extends StatefulWidget {
  const _AnimatedBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.isPending,
    required this.isSeen,
  });

  final String text;
  final bool isMe;
  final bool isPending;
  final bool isSeen;

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.15),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: EdgeInsets.symmetric(vertical: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: widget.isMe ? colors.primary : colors.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
                bottomLeft: widget.isMe ? Radius.circular(16.r) : Radius.zero,
                bottomRight: widget.isMe ? Radius.zero : Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: widget.text.isNotEmpty ? widget.text : '[empty]',
                  fontSize: 14.sp,
                  color: widget.isMe ? colors.onPrimary : colors.onSurface,
                ),
                if (widget.isMe) ...[
                  SizedBox(height: 4.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: Row(
                      key: ValueKey(
                        widget.isPending
                            ? 'pending'
                            : widget.isSeen
                            ? 'seen'
                            : 'sent',
                      ),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isPending
                              ? 'Sending…'
                              : widget.isSeen
                              ? 'Seen'
                              : 'Sent',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: colors.onPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          widget.isPending
                              ? Icons.schedule
                              : widget.isSeen
                              ? Icons.done_all
                              : Icons.done,
                          size: 15.sp,
                          color: colors.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
