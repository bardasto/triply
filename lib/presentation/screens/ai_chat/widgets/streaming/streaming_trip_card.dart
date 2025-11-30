import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../core/services/streaming_trip_service.dart';

/// A minimal iOS-style card that displays a trip being generated in real-time.
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // iOS dark card
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator at top
          _buildProgressIndicator(),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with cancel
                _buildTitleRow(),

                const SizedBox(height: 12),

                // Location & Duration
                _buildMetaInfo(),

                const SizedBox(height: 16),

                // Days progress
                _buildDaysProgress(),

                const SizedBox(height: 12),

                // Status text
                _buildStatusText(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: LinearProgressIndicator(
        value: state.progress,
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        valueColor: AlwaysStoppedAnimation<Color>(
          CupertinoColors.activeBlue.withValues(alpha: 0.8),
        ),
        minHeight: 3,
      ),
    );
  }

  Widget _buildTitleRow() {
    final hasTitle = state.title != null && state.title!.isNotEmpty;

    return Row(
      children: [
        // Generating indicator
        if (!state.isComplete)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : _buildShimmer(width: 180, height: 17),
        ),

        // Cancel button
        if (onCancel != null)
          GestureDetector(
            onTap: onCancel,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: Colors.white.withValues(alpha: 0.3),
              size: 22,
            ),
          ),
      ],
    );
  }

  Widget _buildMetaInfo() {
    final hasCity = state.city != null && state.city!.isNotEmpty;
    final hasDuration = state.durationDays != null && state.durationDays! > 0;
    final hasBudget = state.estimatedBudget != null;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        // Location
        _buildMetaItem(
          icon: CupertinoIcons.location_solid,
          text: hasCity ? '${state.city}' : null,
          width: 80,
        ),

        // Duration
        _buildMetaItem(
          icon: CupertinoIcons.calendar,
          text: hasDuration ? '${state.durationDays} days' : null,
          width: 60,
        ),

        // Budget
        if (hasBudget)
          _buildMetaItem(
            icon: CupertinoIcons.money_euro,
            text: '€${state.estimatedBudget!['min']?.toInt() ?? 0}-${state.estimatedBudget!['max']?.toInt() ?? 0}',
            width: 90,
          ),
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
              ? CupertinoColors.activeBlue
              : Colors.white.withValues(alpha: 0.2),
          size: 14,
        ),
        const SizedBox(width: 4),
        text != null
            ? Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              )
            : _buildShimmer(width: width, height: 13),
      ],
    );
  }

  Widget _buildDaysProgress() {
    final daysCount = state.durationDays ?? 3;
    final loadedDays = state.days.length;

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
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '$loadedDays / $daysCount days',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

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
          const CupertinoActivityIndicator(radius: 8),
        if (!state.isComplete)
          const SizedBox(width: 8),
        Text(
          _getProgressText(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          '${(state.progress * 100).toInt()}%',
          style: TextStyle(
            color: CupertinoColors.activeBlue.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
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
      height: 36,
      decoration: BoxDecoration(
        color: isLoaded
            ? CupertinoColors.activeBlue.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLoaded
              ? CupertinoColors.activeBlue.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'D$dayNumber',
            style: TextStyle(
              color: isLoaded
                  ? CupertinoColors.activeBlue
                  : Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isLoaded && placesCount > 0)
            Text(
              '$placesCount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }
}
