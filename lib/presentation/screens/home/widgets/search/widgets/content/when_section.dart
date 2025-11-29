import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/search_theme.dart';
import '../calendar/when_expanded_content.dart';

/// When section with date selection.
class WhenSection extends StatelessWidget {
  final bool isExpanded;
  final DateTimeRange? selectedDateRange;
  final VoidCallback onToggle;
  final ValueChanged<DateTimeRange> onDateRangeSelected;

  const WhenSection({
    super.key,
    required this.isExpanded,
    required this.selectedDateRange,
    required this.onToggle,
    required this.onDateRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SearchTheme.elementDecoration,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onToggle();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'When',
                  style: SearchTheme.whenTitleStyle,
                ),
                Row(
                  children: [
                    Text(
                      selectedDateRange == null
                          ? 'Add dates'
                          : '${selectedDateRange!.start.day}/${selectedDateRange!.start.month} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}',
                      style: SearchTheme.whenValueStyle,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded)
            WhenExpandedContent(
              selectedDateRange: selectedDateRange,
              onDateRangeSelected: onDateRangeSelected,
            ),
        ],
      ),
    );
  }
}
