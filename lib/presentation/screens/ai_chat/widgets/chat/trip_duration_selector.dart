import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../theme/ai_chat_theme.dart';

/// A widget that displays duration options for creating a trip.
class TripDurationSelector extends StatefulWidget {
  final String cityName;
  final Function(int days) onDurationSelected;

  const TripDurationSelector({
    super.key,
    required this.cityName,
    required this.onDurationSelected,
  });

  @override
  State<TripDurationSelector> createState() => _TripDurationSelectorState();
}

class _TripDurationSelectorState extends State<TripDurationSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int? _selectedDuration;

  static const List<_DurationOption> _options = [
    _DurationOption(days: 1, label: '1 day', description: 'Quick visit'),
    _DurationOption(days: 2, label: '2 days', description: 'Weekend escape'),
    _DurationOption(days: 3, label: '3 days', description: 'Short trip'),
    _DurationOption(days: 5, label: '5 days', description: 'Extended stay'),
    _DurationOption(days: 7, label: '7 days', description: 'Full week'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onOptionTap(int days) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDuration = days;
    });
    // Small delay before calling callback for visual feedback
    Future.delayed(const Duration(milliseconds: 200), () {
      widget.onDurationSelected(days);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.95,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AiChatTheme.messageBorderRadius),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
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
                  children: [
                    // Question text
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How long is your trip?',
                                style: AiChatTheme.messageText.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Creating trip to ${widget.cityName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Duration options as horizontal scroll
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _options.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final option = _options[index];
                          final isSelected = _selectedDuration == option.days;
                          return _buildDurationOption(option, isSelected);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationOption(_DurationOption option, bool isSelected) {
    return GestureDetector(
      onTap: () => _onOptionTap(option.days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              option.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationOption {
  final int days;
  final String label;
  final String description;

  const _DurationOption({
    required this.days,
    required this.label,
    required this.description,
  });
}
