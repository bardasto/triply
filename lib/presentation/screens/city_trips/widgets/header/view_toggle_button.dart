import 'package:flutter/material.dart';
import '../../../../../core/constants/color_constants.dart';

class ViewToggleButton extends StatefulWidget {
  final bool isGridView;
  final ValueChanged<bool> onToggle;
  final bool embedded;

  const ViewToggleButton({
    super.key,
    required this.isGridView,
    required this.onToggle,
    this.embedded = false,
  });

  @override
  State<ViewToggleButton> createState() => _ViewToggleButtonState();
}

class _ViewToggleButtonState extends State<ViewToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    setState(() => _tappedIndex = index);
    _controller.forward();
  }

  void _onTapUp(int index) {
    _controller.reverse().then((_) {
      setState(() => _tappedIndex = null);
    });
    widget.onToggle(index == 1);
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _tappedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleItem(0, Icons.view_agenda_outlined, !widget.isGridView),
        const SizedBox(width: 4),
        _buildToggleItem(1, Icons.grid_view_rounded, widget.isGridView),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
    );
  }

  Widget _buildToggleItem(int index, IconData icon, bool isActive) {
    final isTapped = _tappedIndex == index;

    return GestureDetector(
      onTapDown: (_) => _onTapDown(index),
      onTapUp: (_) => _onTapUp(index),
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale = isTapped ? _scaleAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}
