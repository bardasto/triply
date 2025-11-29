import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

/// Blurred drag handle for search bottom sheet.
class SearchDragHandle extends StatelessWidget {
  const SearchDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: SearchTheme.dragHandleTop,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: SearchTheme.dragHandleBlur,
              sigmaY: SearchTheme.dragHandleBlur,
            ),
            child: Container(
              width: SearchTheme.dragHandleWidth,
              height: SearchTheme.dragHandleHeight,
              decoration: SearchTheme.dragHandleDecoration,
              alignment: Alignment.center,
              child: Container(
                width: SearchTheme.dragHandleBarWidth,
                height: SearchTheme.dragHandleBarHeight,
                decoration: SearchTheme.dragHandleBarDecoration,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
