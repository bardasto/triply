import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../../../../core/services/streaming_trip_service.dart';
import '../../theme/ai_chat_theme.dart';

/// A minimal card that displays a trip being generated in real-time.
/// Uses the same styling as AI chat message bubbles with typewriter effects.
class StreamingTripCard extends StatefulWidget {
  final StreamingTripState state;
  final VoidCallback? onCancel;

  const StreamingTripCard({
    super.key,
    required this.state,
    this.onCancel,
  });

  @override
  State<StreamingTripCard> createState() => _StreamingTripCardState();
}

class _StreamingTripCardState extends State<StreamingTripCard>
    with SingleTickerProviderStateMixin {
  // Track previous values to detect changes
  String? _prevTitle;
  String? _prevCity;
  int? _prevDurationDays;
  Map<String, dynamic>? _prevBudget;

  // Animated text values
  String? _animatedTitle;
  String? _animatedCity;
  String? _animatedDuration;
  String? _animatedBudget;

  // Bounce animation
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Check for initial values that might already be set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForChanges();
    });
  }

  @override
  void didUpdateWidget(StreamingTripCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForChanges();
  }

  void _checkForChanges() {
    debugPrint('🎯 _checkForChanges called: title=${widget.state.title}, city=${widget.state.city}, days=${widget.state.durationDays}');
    debugPrint('🎯 Previous values: title=$_prevTitle, city=$_prevCity, days=$_prevDurationDays');

    // Check title change
    if (widget.state.title != _prevTitle && widget.state.title != null && widget.state.title!.isNotEmpty) {
      debugPrint('✨ Title changed: ${widget.state.title}');
      _prevTitle = widget.state.title;
      _animateText(widget.state.title!, (v) => _animatedTitle = v);
    }

    // Check city change
    if (widget.state.city != _prevCity && widget.state.city != null && widget.state.city!.isNotEmpty) {
      debugPrint('✨ City changed: ${widget.state.city}');
      _prevCity = widget.state.city;
      _animateText(widget.state.city!, (v) => _animatedCity = v);
    }

    // Check duration change
    if (widget.state.durationDays != _prevDurationDays && widget.state.durationDays != null && widget.state.durationDays! > 0) {
      debugPrint('✨ Duration changed: ${widget.state.durationDays}');
      _prevDurationDays = widget.state.durationDays;
      _animateText('${widget.state.durationDays} days', (v) => _animatedDuration = v);
    }

    // Check budget change - also update when values change (e.g., when real prices come in)
    final currentBudget = widget.state.estimatedBudget;
    if (currentBudget != null) {
      final currentMin = _parseToInt(currentBudget['min']);
      final currentMax = _parseToInt(currentBudget['max']);
      final prevMin = _prevBudget != null ? _parseToInt(_prevBudget!['min']) : null;
      final prevMax = _prevBudget != null ? _parseToInt(_prevBudget!['max']) : null;

      // Update if budget is new OR if values have changed significantly
      if (_prevBudget == null || currentMin != prevMin || currentMax != prevMax) {
        debugPrint('✨ Budget changed: $currentBudget (prev: $_prevBudget)');
        _prevBudget = Map<String, dynamic>.from(currentBudget);
        final budgetText = '€${currentMin ?? 0}-${currentMax ?? 0}';
        _animateText(budgetText, (v) => _animatedBudget = v);
      }
    }
  }

  /// Helper to safely parse value to int (handles both int and String)
  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _animateText(String fullText, void Function(String) setter) async {
    // Reset to empty first
    if (mounted) {
      setState(() {
        setter('');
      });
    }

    // Animate character by character
    for (int i = 0; i <= fullText.length; i++) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 25));
      if (mounted) {
        setState(() {
          setter(fullText.substring(0, i));
        });
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

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
          child: GestureDetector(
            onTapDown: (_) => _bounceController.forward(),
            onTapUp: (_) => _bounceController.reverse(),
            onTapCancel: () => _bounceController.reverse(),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    // Same as AI message bubble background
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
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

                      // Progress indicator removed - was causing visual glitch
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    // Title is ready when it exists and is not empty
    final hasTitle = widget.state.title != null && widget.state.title!.isNotEmpty;
    // Use animated title if available, otherwise use original (or empty if animating)
    final displayTitle = _animatedTitle ?? (hasTitle ? widget.state.title! : '');
    final showTitle = displayTitle.isNotEmpty;

    return Row(
      children: [
        // Generating indicator - purple glow
        if (!widget.state.isComplete)
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

        // Title with typewriter effect
        Expanded(
          child: showTitle
              ? Text(
                  displayTitle,
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

        // Cancel button removed - users prefer to wait for generation
      ],
    );
  }

  Widget _buildMetaInfo() {
    final hasCity = widget.state.city != null && widget.state.city!.isNotEmpty;
    final hasDuration = widget.state.durationDays != null && widget.state.durationDays! > 0;
    final hasBudget = widget.state.estimatedBudget != null;

    // Use animated values or show shimmer
    final displayCity = _animatedCity ?? (hasCity ? widget.state.city! : null);
    final displayDuration = _animatedDuration ?? (hasDuration ? '${widget.state.durationDays} days' : null);
    final displayBudget = _animatedBudget ?? (hasBudget ? '€${widget.state.estimatedBudget!['min']?.toInt() ?? 0}-${widget.state.estimatedBudget!['max']?.toInt() ?? 0}' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location with typewriter
        _buildMetaItem(
          icon: CupertinoIcons.location_solid,
          text: displayCity?.isNotEmpty == true ? displayCity : null,
          width: 100,
        ),

        const SizedBox(height: 8),

        // Duration with typewriter
        _buildMetaItem(
          icon: CupertinoIcons.calendar,
          text: displayDuration?.isNotEmpty == true ? displayDuration : null,
          width: 70,
        ),

        // Budget with typewriter
        if (hasBudget) ...[
          const SizedBox(height: 8),
          _buildMetaItem(
            icon: CupertinoIcons.money_euro,
            text: displayBudget?.isNotEmpty == true ? displayBudget : null,
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
    final daysCount = widget.state.durationDays;
    final loadedDays = widget.state.days.length;

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
            final isLoaded = widget.state.days.containsKey(dayNum);
            final placesCount = widget.state.places.entries
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
        if (!widget.state.isComplete)
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
        if (!widget.state.isComplete)
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
          '${(widget.state.progress * 100).toInt()}%',
          style: const TextStyle(
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
    if (widget.state.progress < 0.15) return 'Analyzing request...';
    if (widget.state.progress < 0.30) return 'Creating structure...';
    if (widget.state.progress < 0.50) return 'Planning activities...';
    if (widget.state.progress < 0.75) return 'Finding places...';
    if (widget.state.progress < 0.90) return 'Loading images...';
    if (widget.state.progress < 1.0) return 'Finalizing...';
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
