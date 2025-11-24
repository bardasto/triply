import 'package:flutter/material.dart';

/// A widget that displays an image with pinch-to-zoom functionality.
/// Automatically resets zoom level when interaction ends (Telegram-style).
class ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final Function(TapUpDetails)? onTapUp;
  final double minScale;
  final double maxScale;
  final Duration resetDuration;
  final BoxFit fit;
  final Widget? errorWidget;

  const ZoomableImage({
    super.key,
    required this.imageUrl,
    this.onTapUp,
    this.minScale = 1.0,
    this.maxScale = 4.0,
    this.resetDuration = const Duration(milliseconds: 200),
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.resetDuration,
    )..addListener(_onAnimationUpdate);
  }

  void _onAnimationUpdate() {
    if (_animation != null) {
      _transformationController.value = _animation!.value;
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetAnimation() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward(from: 0);
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          color: Colors.grey[900],
          child: const Center(
            child: Icon(Icons.image_not_supported, color: Colors.white54),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: widget.onTapUp,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        panEnabled: false,
        clipBehavior: Clip.none,
        onInteractionEnd: (details) => _resetAnimation(),
        child: Image.network(
          widget.imageUrl,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        ),
      ),
    );
  }
}
