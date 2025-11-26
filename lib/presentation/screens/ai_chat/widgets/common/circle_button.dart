import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/ai_chat_theme.dart';

/// A circular icon button with consistent styling.
class CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color iconColor;

  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = AiChatTheme.headerButtonSize,
    this.iconSize = 20,
    this.backgroundColor,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
