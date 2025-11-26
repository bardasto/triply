import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/color_constants.dart';
import '../common/typing_animation.dart';

/// Widget showing typing animation with progress indicator.
class TypingIndicator extends StatefulWidget {
  final double progress;

  const TypingIndicator({
    super.key,
    required this.progress,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> {
  int _lastStage = -1;

  /// Get stage based on progress (0-4)
  int _getStage(double progress) {
    if (progress < 0.15) return 0;
    if (progress < 0.35) return 1;
    if (progress < 0.55) return 2;
    if (progress < 0.75) return 3;
    if (progress < 0.90) return 4;
    return 5;
  }

  /// Get text for current stage
  String _getStageText(int stage) {
    switch (stage) {
      case 0:
        return 'Analyzing your request...';
      case 1:
        return 'Finding the best destinations...';
      case 2:
        return 'Planning activities & experiences...';
      case 3:
        return 'Selecting accommodations...';
      case 4:
        return 'Finalizing your itinerary...';
      case 5:
        return 'Almost there...';
      default:
        return 'Generating your trip...';
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentStage = _getStage(widget.progress);
    if (currentStage != _lastStage && currentStage > _lastStage) {
      // Haptic feedback on stage change
      HapticFeedback.lightImpact();
      _lastStage = currentStage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _getStage(widget.progress);
    final stageText = _getStageText(stage);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const TypingAnimation(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          stageText,
                          key: ValueKey(stage),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 4,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0,
                        end: widget.progress,
                      ),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
