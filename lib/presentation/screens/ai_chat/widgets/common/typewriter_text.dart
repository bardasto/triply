import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that displays text with a smooth typewriter animation effect.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDuration;
  final bool enableHaptic;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 10),
    this.enableHaptic = true,
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _charCount;
  int _lastHapticIndex = -1;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    final totalDuration = Duration(
      milliseconds: widget.text.length * widget.charDuration.inMilliseconds,
    );

    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    _charCount = IntTween(begin: 0, end: widget.text.length).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    _charCount.addListener(_onAnimationUpdate);
    _controller.addStatusListener(_onAnimationStatus);

    _controller.forward();
  }

  void _onAnimationUpdate() {
    final currentIndex = _charCount.value;

    // Haptic feedback every 5 characters for smooth effect
    if (widget.enableHaptic && currentIndex > _lastHapticIndex) {
      if (currentIndex % 5 == 0 && currentIndex > 0) {
        HapticFeedback.selectionClick();
      }
      _lastHapticIndex = currentIndex;
    }

    setState(() {});
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call();
    }
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.dispose();
      _lastHapticIndex = -1;
      _initAnimation();
    }
  }

  @override
  void dispose() {
    _charCount.removeListener(_onAnimationUpdate);
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedText = widget.text.substring(0, _charCount.value);

    return Text(
      displayedText,
      style: widget.style,
    );
  }
}
