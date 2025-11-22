import 'dart:ui';
import 'package:flutter/material.dart';
import 'search_modal.dart';

class AnimatedSearchBar extends StatefulWidget {
  final ValueChanged<bool>? onExpansionChanged;
  final ScrollController? scrollController;

  const AnimatedSearchBar({
    super.key,
    this.onExpansionChanged,
    this.scrollController,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar> {
  void _handleSearchTap() {
    // Open SearchModal
    SearchModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: _handleSearchTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
