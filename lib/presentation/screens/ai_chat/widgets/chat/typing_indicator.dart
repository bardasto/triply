import 'package:flutter/material.dart';

import '../common/typing_animation.dart';

/// Simple typing indicator showing three animated dots.
class TypingIndicator extends StatelessWidget {
  final double progress;

  const TypingIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const TypingAnimation(),
          ),
        ],
      ),
    );
  }
}
