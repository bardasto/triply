import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/ai_chat_theme.dart';

/// A button widget with bounce animation on tap.
class BounceableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const BounceableButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.9,
  });

  @override
  State<BounceableButton> createState() => _BounceableButtonState();
}

class _BounceableButtonState extends State<BounceableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AiChatTheme.bounceAnimationDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _controller.forward().then((_) => _controller.reverse());
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
