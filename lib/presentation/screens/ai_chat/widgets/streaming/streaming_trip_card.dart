import 'package:flutter/material.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/services/streaming_trip_service.dart';

/// A card that displays a trip being generated in real-time via streaming.
/// Shows skeleton placeholders that fill in as data arrives.
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and progress
          _buildHeader(),

          // Trip info skeleton/data
          _buildTripInfo(),

          // Days list
          _buildDaysList(),

          // Progress indicator at bottom
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hasTitle = state.title != null && state.title!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Animated icon
          const _AnimatedGeneratingIcon(),
          const SizedBox(width: 12),

          // Title or skeleton
          Expanded(
            child: hasTitle
                ? _AnimatedAppear(
                    child: Text(
                      state.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : const _SkeletonLine(width: 200, height: 20),
          ),

          // Cancel button
          if (onCancel != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildTripInfo() {
    final hasCity = state.city != null && state.city!.isNotEmpty;
    final hasDuration = state.durationDays != null && state.durationDays! > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Location
          Icon(
            Icons.location_on,
            color: hasCity ? AppColors.primary : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 4),
          hasCity
              ? _AnimatedAppear(
                  child: Text(
                    '${state.city}, ${state.country ?? ''}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
              : const _SkeletonLine(width: 100, height: 14),

          const SizedBox(width: 16),

          // Duration
          Icon(
            Icons.calendar_today,
            color: hasDuration ? AppColors.primary : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 4),
          hasDuration
              ? _AnimatedAppear(
                  child: Text(
                    '${state.durationDays} days',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
              : const _SkeletonLine(width: 60, height: 14),
        ],
      ),
    );
  }

  Widget _buildDaysList() {
    final daysCount = state.durationDays ?? 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Itinerary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Days
          ...List.generate(daysCount, (index) {
            final dayNum = index + 1;
            final dayData = state.days[dayNum];
            final hasDay = dayData != null;

            // Get places for this day
            final dayPlaces = state.places.entries
                .where((e) => e.key.startsWith('$dayNum-'))
                .map((e) => e.value)
                .toList();

            return _DayItem(
              dayNumber: dayNum,
              title: dayData?['title'] as String?,
              description: dayData?['description'] as String?,
              places: dayPlaces,
              isLoaded: hasDay,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getProgressText(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressText() {
    if (state.progress < 0.15) return 'Analyzing your request...';
    if (state.progress < 0.30) return 'Creating trip structure...';
    if (state.progress < 0.50) return 'Planning daily activities...';
    if (state.progress < 0.75) return 'Finding best places...';
    if (state.progress < 0.90) return 'Loading images...';
    return 'Finalizing your trip...';
  }
}

/// A single day item in the streaming card
class _DayItem extends StatelessWidget {
  final int dayNumber;
  final String? title;
  final String? description;
  final List<Map<String, dynamic>> places;
  final bool isLoaded;

  const _DayItem({
    required this.dayNumber,
    this.title,
    this.description,
    required this.places,
    required this.isLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLoaded ? AppColors.primary.withValues(alpha: 0.3) : Colors.white12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLoaded ? AppColors.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Day $dayNumber',
                  style: TextStyle(
                    color: isLoaded ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: isLoaded && title != null
                    ? _AnimatedAppear(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : const _SkeletonLine(width: 150, height: 14),
              ),
            ],
          ),

          // Places
          if (places.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: places.map((placeData) {
                final place = placeData['place'] as Map<String, dynamic>?;
                final name = place?['name'] as String? ?? '';
                return _AnimatedAppear(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          name.length > 20 ? '${name.substring(0, 20)}...' : name,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else if (isLoaded) ...[
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (i) => const Padding(
                padding: EdgeInsets.only(right: 6),
                child: _SkeletonLine(width: 80, height: 24, borderRadius: 6),
              )),
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated generating icon
class _AnimatedGeneratingIcon extends StatefulWidget {
  const _AnimatedGeneratingIcon();

  @override
  State<_AnimatedGeneratingIcon> createState() => _AnimatedGeneratingIconState();
}

class _AnimatedGeneratingIconState extends State<_AnimatedGeneratingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}

/// Simple animated skeleton line (no shimmer dependency)
class _SkeletonLine extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonLine({
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  State<_SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<_SkeletonLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Animated appear widget
class _AnimatedAppear extends StatefulWidget {
  final Widget child;

  const _AnimatedAppear({required this.child});

  @override
  State<_AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<_AnimatedAppear>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
