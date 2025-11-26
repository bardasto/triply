import 'package:flutter/material.dart';

import '../../theme/ai_chat_theme.dart';
import '../common/bounceable_button.dart';

/// The chat input field with send and microphone buttons.
class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color backgroundColor;
  final VoidCallback onSend;
  final VoidCallback onVoiceInput;

  const ChatInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.backgroundColor,
    required this.onSend,
    required this.onVoiceInput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor.withValues(alpha: 0.0),
            backgroundColor,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44,
                maxHeight: 100,
              ),
              decoration: BoxDecoration(
                color: AiChatTheme.inputBackground,
                borderRadius:
                    BorderRadius.circular(AiChatTheme.inputBorderRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardAppearance: Brightness.dark,
                      decoration: InputDecoration(
                        hintText: 'Romantic weekend in Paris ',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: BounceableButton(
                      onTap: onVoiceInput,
                      child: Container(
                        width: AiChatTheme.micButtonSize,
                        height: AiChatTheme.micButtonSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          BounceableButton(
            onTap: onSend,
            child: Container(
              width: AiChatTheme.sendButtonSize,
              height: AiChatTheme.sendButtonSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
