import 'package:flutter/material.dart';

import '../../models/chat_mode.dart';
import '../../theme/ai_chat_theme.dart';
import '../common/circle_button.dart';

/// The header for the chat screen.
class ChatHeader extends StatelessWidget {
  final bool showWelcome;
  final ChatMode currentMode;
  final Animation<double>? welcomeAnimation;
  final VoidCallback onClose;
  final VoidCallback onMenuTap;
  final Color backgroundColor;

  const ChatHeader({
    super.key,
    required this.showWelcome,
    required this.currentMode,
    this.welcomeAnimation,
    required this.onClose,
    required this.onMenuTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleButton(
                    icon: Icons.close,
                    onTap: onClose,
                  ),
                  Expanded(
                    child: _buildTitle(),
                  ),
                  CircleButton(
                    icon: Icons.menu,
                    onTap: onMenuTap,
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 0.5,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    // Always show the mode's header title
    final titleText = currentMode.headerTitle;

    if (showWelcome && welcomeAnimation != null) {
      return FadeTransition(
        opacity: welcomeAnimation!,
        child: Text(
          titleText,
          style: AiChatTheme.welcomeTitle.copyWith(
            color: Colors.white.withValues(alpha: 0.95),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Text(
      titleText,
      style: AiChatTheme.headerTitle,
      textAlign: TextAlign.center,
    );
  }
}
