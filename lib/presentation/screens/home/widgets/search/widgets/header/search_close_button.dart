import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

/// Blurred close button for search bottom sheet.
class SearchCloseButton extends StatelessWidget {
  final VoidCallback onClose;

  const SearchCloseButton({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: SearchTheme.closeButtonTop,
      right: SearchTheme.closeButtonRight,
      child: GestureDetector(
        onTap: onClose,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: SearchTheme.closeButtonBlur,
              sigmaY: SearchTheme.closeButtonBlur,
            ),
            child: Container(
              width: SearchTheme.closeButtonSize,
              height: SearchTheme.closeButtonSize,
              decoration: SearchTheme.closeButtonDecoration,
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: SearchTheme.closeButtonIconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
