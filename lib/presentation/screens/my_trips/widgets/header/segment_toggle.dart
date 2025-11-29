import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/color_constants.dart';

/// iOS/Telegram style segment toggle for switching between Trips and Places
/// Syncs with PageController for smooth swipe animations
class SegmentToggle extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;
  final List<int>? counts;
  final PageController? pageController;

  const SegmentToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.labels,
    this.counts,
    this.pageController,
  });

  @override
  State<SegmentToggle> createState() => _SegmentToggleState();
}

class _SegmentToggleState extends State<SegmentToggle> {
  double _currentPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.selectedIndex.toDouble();
    widget.pageController?.addListener(_onPageScroll);
  }

  @override
  void didUpdateWidget(SegmentToggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update listener if pageController changed
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController?.removeListener(_onPageScroll);
      widget.pageController?.addListener(_onPageScroll);
    }

    // If no pageController, animate based on selectedIndex
    if (widget.pageController == null && oldWidget.selectedIndex != widget.selectedIndex) {
      setState(() {
        _currentPosition = widget.selectedIndex.toDouble();
      });
    }
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_onPageScroll);
    super.dispose();
  }

  void _onPageScroll() {
    if (widget.pageController?.hasClients == true) {
      final page = widget.pageController!.page ?? widget.selectedIndex.toDouble();
      setState(() {
        _currentPosition = page.clamp(0.0, (widget.labels.length - 1).toDouble());
      });
    }
  }

  void _onTap(int index) {
    if (index != widget.selectedIndex) {
      HapticFeedback.lightImpact();
      widget.onChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(15),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / widget.labels.length;
          const horizontalPadding = 3.0;

          return Stack(
            children: [
              // Animated selection indicator - now synced with page position
              Positioned(
                left: _currentPosition * segmentWidth + horizontalPadding,
                top: 2,
                bottom: 2,
                width: segmentWidth - (horizontalPadding * 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Segment labels
              Row(
                children: List.generate(widget.labels.length, (index) {
                  // Calculate how "selected" this segment is (0.0 to 1.0)
                  final distanceFromCurrent = (_currentPosition - index).abs();
                  final selectionProgress = (1.0 - distanceFromCurrent).clamp(0.0, 1.0);

                  final count = widget.counts != null && index < widget.counts!.length
                      ? widget.counts![index]
                      : null;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.labels[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selectionProgress > 0.5 ? FontWeight.w600 : FontWeight.w500,
                                color: Color.lerp(
                                  Colors.white.withValues(alpha: 0.6),
                                  Colors.white,
                                  selectionProgress,
                                ),
                              ),
                            ),
                            if (count != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.white.withValues(alpha: 0.2),
                                    selectionProgress,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color.lerp(
                                      Colors.white.withValues(alpha: 0.5),
                                      Colors.white,
                                      selectionProgress,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
