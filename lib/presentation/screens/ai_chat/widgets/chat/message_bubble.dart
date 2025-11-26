import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../models/chat_message.dart';
import '../../theme/ai_chat_theme.dart';
import '../common/typewriter_text.dart';

/// A chat message bubble widget.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool useTypewriter;
  final VoidCallback? onTypewriterComplete;

  const MessageBubble({
    super.key,
    required this.message,
    this.useTypewriter = false,
    this.onTypewriterComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: AiChatTheme.messageWidthFactor,
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Align(
            alignment:
                message.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: AiChatTheme.messagePadding,
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AiChatTheme.messageBorderRadius),
              ),
              child: _buildMessageText(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageText() {
    if (useTypewriter && !message.isUser) {
      return TypewriterText(
        text: message.text,
        style: AiChatTheme.messageText,
        onComplete: onTypewriterComplete,
      );
    }

    return Text(
      message.text,
      style: AiChatTheme.messageText,
    );
  }
}
