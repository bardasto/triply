// lib/core/utils/custom_scroll_behavior.dart
import 'package:flutter/material.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // ✅ Убираем overscroll glow effect (серый блок)
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // ✅ Используем bouncing physics для плавности
    return const BouncingScrollPhysics();
  }
}
