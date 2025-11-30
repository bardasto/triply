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
  final VoidCallback? onCreateTrip;

  const MessageBubble({
    super.key,
    required this.message,
    this.useTypewriter = false,
    this.onTypewriterComplete,
    this.onCreateTrip,
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
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
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
                if (onCreateTrip != null && message.canCreateTrip)
                  _buildCreateTripButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTripButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: onCreateTrip,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Create Trip',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
