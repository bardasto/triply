import 'package:flutter/material.dart';

/// Zoomable Image Widget (Telegram-style)
class ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final Function(TapUpDetails) onTapUp;
  final Widget placeholderWidget;

  const ZoomableImage({
    super.key,
    required this.imageUrl,
    required this.onTapUp,
    required this.placeholderWidget,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  late TransformationController _controller;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _controller.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetAnimation() {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: widget.onTapUp,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        panEnabled: false,
        clipBehavior: Clip.none,
        onInteractionEnd: (details) {
          _resetAnimation();
        },
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => widget.placeholderWidget,
        ),
      ),
    );
  }
}
