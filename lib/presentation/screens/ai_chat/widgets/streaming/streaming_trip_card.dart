import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/services/streaming_trip_service.dart';
import '../../theme/ai_chat_theme.dart';

/// A minimal card that displays a trip being generated in real-time.
/// Uses the same styling as AI chat message bubbles.
class StreamingTripCard extends StatelessWidget {
  final StreamingTripState state;
  final VoidCallback? onCancel;

  const StreamingTripCard({
    super.key,
    required this.state,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Use same width as message bubbles
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: AiChatTheme.messageWidthFactor,
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                // Same as AI message bubble background
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                // Purple border like message bubbles
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                // Purple glow like message bubbles
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with cancel
                      _buildTitleRow(),

                      const SizedBox(height: 12),

                      // Divider line
                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),

                      const SizedBox(height: 14),

                      // Location & Duration
                      _buildMetaInfo(),

                      const SizedBox(height: 18),

                      // Days progress (on new line)
                      _buildDaysProgress(),

                      const SizedBox(height: 14),

                      // Status text
                      _buildStatusText(),
                    ],
                  ),
                ),

                // Progress indicator at bottom (inside rounded corners)
                _buildProgressIndicator(),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: LinearProgressIndicator(
        value: state.progress,
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        valueColor: AlwaysStoppedAnimation<Color>(
          AppColors.primary.withValues(alpha: 0.8),
        ),
        minHeight: 4,
      ),
    );
  }

  Widget _buildTitleRow() {
    final hasTitle = state.title != null && state.title!.isNotEmpty;

    return Row(
      children: [
        // Generating indicator - purple glow
        if (!state.isComplete)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

        // Title
        Expanded(
          child: hasTitle
              ? Text(
                  state.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : _buildShimmer(width: 200, height: 18),
        ),

        // Cancel button
        if (onCancel != null)
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
          ),
      ],
    );
  }

  Widget _buildMetaInfo() {
    final hasCity = state.city != null && state.city!.isNotEmpty;
    final hasDuration = state.durationDays != null && state.durationDays! > 0;
    final hasBudget = state.estimatedBudget != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location
        _buildMetaItem(
          icon: CupertinoIcons.location_solid,
          text: hasCity ? '${state.city}' : null,
          width: 100,
        ),

        const SizedBox(height: 8),

        // Duration
        _buildMetaItem(
          icon: CupertinoIcons.calendar,
          text: hasDuration ? '${state.durationDays} days' : null,
          width: 70,
        ),

        // Budget
        if (hasBudget) ...[
          const SizedBox(height: 8),
          _buildMetaItem(
            icon: CupertinoIcons.money_euro,
            text: '€${state.estimatedBudget!['min']?.toInt() ?? 0}-${state.estimatedBudget!['max']?.toInt() ?? 0}',
            width: 100,
          ),
        ],
      ],
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    String? text,
    required double width,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: text != null
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.25),
          size: 16,
        ),
        const SizedBox(width: 8),
        text != null
            ? Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              )
            : _buildShimmer(width: width, height: 15),
      ],
    );
  }

  Widget _buildDaysProgress() {
    final daysCount = state.durationDays;
    final loadedDays = state.days.length;

    // If durationDays is not yet known (skeleton not received), show placeholder
    if (daysCount == null || daysCount == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itinerary',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          // Shimmer placeholder for days
          Row(
            children: [
              Expanded(child: _buildShimmer(width: double.infinity, height: 42)),
              const SizedBox(width: 6),
              Expanded(child: _buildShimmer(width: double.infinity, height: 42)),
              const SizedBox(width: 6),
              Expanded(child: _buildShimmer(width: double.infinity, height: 42)),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Itinerary',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '$loadedDays / $daysCount days',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Day dots
        Row(
          children: List.generate(daysCount, (index) {
            final dayNum = index + 1;
            final isLoaded = state.days.containsKey(dayNum);
            final placesCount = state.places.entries
                .where((e) => e.key.startsWith('$dayNum-'))
                .length;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < daysCount - 1 ? 6 : 0),
                child: _DayDot(
                  dayNumber: dayNum,
                  isLoaded: isLoaded,
                  placesCount: placesCount,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    return Row(
      children: [
        if (!state.isComplete)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        if (!state.isComplete)
          const SizedBox(width: 10),
        Text(
          _getProgressText(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          '${(state.progress * 100).toInt()}%',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  String _getProgressText() {
    if (state.progress < 0.15) return 'Analyzing request...';
    if (state.progress < 0.30) return 'Creating structure...';
    if (state.progress < 0.50) return 'Planning activities...';
    if (state.progress < 0.75) return 'Finding places...';
    if (state.progress < 0.90) return 'Loading images...';
    if (state.progress < 1.0) return 'Finalizing...';
    return 'Complete';
  }
}

/// Compact day indicator dot
class _DayDot extends StatelessWidget {
  final int dayNumber;
  final bool isLoaded;
  final int placesCount;

  const _DayDot({
    required this.dayNumber,
    required this.isLoaded,
    required this.placesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isLoaded
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLoaded
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Day $dayNumber',
            style: TextStyle(
              color: isLoaded
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isLoaded && placesCount > 0)
            Text(
              '$placesCount places',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
