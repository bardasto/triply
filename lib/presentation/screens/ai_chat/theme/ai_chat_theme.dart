import 'package:flutter/material.dart';

/// Theme constants for AI Chat screen.
class AiChatTheme {
  AiChatTheme._();

  // Colors
  static const Color cardBackground = Color(0xFF1E1E1E);
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color lightBackground = Color(0xFF2A2A2A);

  // Dimensions
  static const double headerHeight = 69.0;
  static const double sidebarWidthFactor = 0.85;
  static const double tripCardWidthFactor = 0.8;
  static const double messageWidthFactor = 0.9;
  static const double tripCardImageHeight = 200.0;

  // Border radius
  static const double cardBorderRadius = 16.0;
  static const double messageBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;
  static const double inputBorderRadius = 22.0;

  // Button sizes
  static const double headerButtonSize = 36.0;
  static const double sendButtonSize = 44.0;
  static const double micButtonSize = 32.0;

  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets messagePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets cardContentPadding = EdgeInsets.all(12);

  // Animation durations
  static const Duration welcomeAnimationDuration = Duration(milliseconds: 800);
  static const Duration sidebarAnimationDuration = Duration(milliseconds: 300);
  static const Duration bounceAnimationDuration = Duration(milliseconds: 70);
  static const Duration typingAnimationDuration = Duration(milliseconds: 1200);

  // Text styles
  static const TextStyle headerTitle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle welcomeTitle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle sidebarTitle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle messageText = TextStyle(
    color: Colors.white,
    fontSize: 16,
    height: 1.45,
  );

  static TextStyle suggestionText = TextStyle(
    color: Colors.white.withValues(alpha: 0.9),
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // Decoration helpers
  static BoxDecoration get headerButtonDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      );

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? cardBackground,
        borderRadius: BorderRadius.circular(cardBorderRadius),
      );
}
