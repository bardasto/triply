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
    final buttonSize = iconSize + 16; // icon + padding

    return Positioned(
      top: top,
      right: right,
      child: BounceableButton(
        onTap: onClose,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.5,
                ),
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
