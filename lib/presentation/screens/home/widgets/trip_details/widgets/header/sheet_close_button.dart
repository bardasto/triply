import 'dart:ui';
import 'package:flutter/material.dart';
import '../common/bounceable_button.dart';

/// Blurred close button for bottom sheet.
/// Positioned at top-right with backdrop blur effect.
class SheetCloseButton extends StatelessWidget {
  final VoidCallback onClose;
  final double top;
  final double right;
  final double blurSigma;
  final double iconSize;

  const SheetCloseButton({
    super.key,
    required this.onClose,
    this.top = 12,
    this.right = 16,
    this.blurSigma = 8,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      child: BounceableButton(
        onTap: onClose,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
