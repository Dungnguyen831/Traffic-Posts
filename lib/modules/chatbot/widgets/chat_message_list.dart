import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:traffic_app/modules/chatbot/widgets/user_message_bubble.dart';

import '../controllers/chatbot_controller.dart';
import 'chat_bubble.dart';
import 'suggestion_chips.dart';

class ChatMessageList extends StatelessWidget {
  final ChatbotController controller;
  const ChatMessageList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msgs = controller.messages;
      final isTyping = controller.isTyping.value;
      final showSuggestions = msgs.length <= 1 && !isTyping;
      final extraItems = (isTyping ? 1 : 0) + (showSuggestions ? 1 : 0);

      return ListView.builder(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom: 12.h,
        ),
        itemCount: msgs.length + extraItems,
        itemBuilder: (ctx, index) {
          // Gợi ý nhanh (khi hội thoại trống)
          if (showSuggestions && index == msgs.length) {
            return SuggestionChips(controller: controller);
          }
          // Typing / Streaming bubble
          if (isTyping && index == msgs.length + (showSuggestions ? 1 : 0)) {
            return Obx(() {
              final text = controller.streamingText.value;
              return text.isEmpty
                  ? const TypingBubble()
                  : AiMessageBubble(text: text, isStreaming: true);
            });
          }
          // Tin nhắn thông thường
          final msg = msgs[index];
          return msg.isUser
              ? UserMessageBubble(msg: msg)
              : AiMessageBubble(
                  text: msg.id == 'welcome' ? 'chatbot_welcome'.tr : msg.text,
                  timestamp: msg.timestamp,
                  isError: msg.isError,
                );
        },
      );
    });
  }
}
