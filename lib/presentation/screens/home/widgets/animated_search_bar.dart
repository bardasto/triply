import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
        onTap: () {
          HapticFeedback.lightImpact();
          _controller.forward().then((_) => _controller.reverse());
          _handleSearchTap();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
            );
          },
        ),
      ),
    );
  }
}
