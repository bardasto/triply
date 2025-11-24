import 'dart:ui';
import 'package:flutter/material.dart';

/// Blurred drag handle for bottom sheet.
/// Positioned at top of sheet with backdrop blur effect.
class SheetDragHandle extends StatelessWidget {
  final double top;
  final double width;
  final double height;
  final double handleWidth;
  final double handleHeight;
  final double blurSigma;
  final double borderRadius;

  const SheetDragHandle({
    super.key,
    this.top = 12,
    this.width = 50,
    this.height = 24,
    this.handleWidth = 32,
    this.handleHeight = 4,
    this.blurSigma = 10,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              alignment: Alignment.center,
              child: Container(
                width: handleWidth,
                height: handleHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(handleHeight / 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
