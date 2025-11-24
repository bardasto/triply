import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../common/bounceable_button.dart';

/// Expandable description section with "See more/See less" functionality.
class TripDescriptionSection extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool isDark;
  final int trimLength;

  const TripDescriptionSection({
    super.key,
    required this.description,
    required this.isExpanded,
    required this.onToggle,
    required this.isDark,
    this.trimLength = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) return const SizedBox.shrink();

    final theme = TripDetailsTheme.of(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this trip',
            style: theme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildDescriptionText(theme),
        ],
      ),
    );
  }

  Widget _buildDescriptionText(TripDetailsTheme theme) {
    if (description.length <= trimLength) {
      return Text(description, style: theme.bodyMedium);
    }

    return Text.rich(
      TextSpan(
        style: theme.bodyMedium,
        children: [
          TextSpan(
            text: isExpanded
                ? description
                : '${description.substring(0, trimLength)}...',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: BounceableButton(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  isExpanded ? 'See less' : 'See more',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
