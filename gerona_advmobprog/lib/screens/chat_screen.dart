import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';

// Enhancement (Chat Support):
// A real (if simple, fully client-side) chat: messages are held in state,
// the input field and send button work, and a small keyword-based responder
// replies automatically. Colors are pulled from the current Theme's
// ColorScheme (not hardcoded), so this screen matches Profile/Cart/Settings
// and switches correctly with the app's dark mode toggle.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.userDisplayName});

  // Optional: pass the signed-in user's name for a personalized greeting.
  final String? userDisplayName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isBotTyping = false;

  @override
  void initState() {
    super.initState();
    final name = widget.userDisplayName;
    _messages.add(
      _ChatMessage(
        text: name != null && name.isNotEmpty
            ? 'Hello, $name! Welcome to our customer support. How can we help you today?'
            : 'Hello! Welcome to our customer support. How can we help you today?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isBotTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _messages.add(
          _ChatMessage(text: _generateReply(text), isUser: false),
        );
      });
      _scrollToBottom();
    });
  }

  String _generateReply(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('order') || RegExp(r'#?ord-?\d+').hasMatch(lower)) {
      return 'Thanks for the details! Your order is currently being processed. We appreciate your patience.';
    }
    if (lower.contains('refund') || lower.contains('cancel')) {
      return 'I can help with that. Could you share your order number so I can look into the refund/cancellation?';
    }
    if (lower.contains('shipping') || lower.contains('deliver')) {
      return 'Standard delivery usually takes 3-5 business days. Do you have an order number I can check for you?';
    }
    if (lower.contains('hello') || lower.contains('hi') || lower.contains('hey')) {
      return 'Hi there! What can I help you with today?';
    }
    if (lower.contains('thank')) {
      return "You're welcome! Is there anything else I can help you with?";
    }
    return 'Got it! Could you share a bit more detail, such as your order number, so I can assist further?';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Chat Support',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return _typingBubble(colors);
                }
                final message = _messages[index];
                return _messageBubble(
                  text: message.text,
                  isUser: message.isUser,
                  colors: colors,
                );
              },
            ),
          ),

          // Message input.
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        style: TextStyle(fontSize: 14.sp),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(fontSize: 14.sp),
                          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      radius: 22.r,
                      backgroundColor: colors.primary,
                      child: Icon(
                        Icons.send,
                        color: colors.onPrimary,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble({
    required String text,
    required bool isUser,
    required ColorScheme colors,
  }) {
    final bubbleColor = isUser ? colors.primary : colors.surfaceContainerLow;
    final textColor = isUser ? colors.onPrimary : colors.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 280.w),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isUser ? 16.r : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16.r),
          ),
        ),
        child: CustomText(text: text, fontSize: 14.sp, color: textColor),
      ),
    );
  }

  Widget _typingBubble(ColorScheme colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomRight: Radius.circular(16.r),
          ),
        ),
        child: CustomText(
          text: 'Typing...',
          fontSize: 13.sp,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}