import 'package:flutter/material.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';

/// Section displaying what's included in the trip.
class TripIncludesSection extends StatelessWidget {
  final List<dynamic> includes;
  final bool isDark;

  const TripIncludesSection({
    super.key,
    required this.includes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (includes.isEmpty) return const SizedBox.shrink();

    final theme = TripDetailsTheme.of(isDark);

    return Padding(
      padding: TripDetailsTheme.paddingAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's Included", style: theme.titleMedium),
          const SizedBox(height: 12),
          ...includes.map((item) => _buildIncludeItem(item, theme)),
        ],
      ),
    );
  }

  Widget _buildIncludeItem(dynamic item, TripDetailsTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.toString(),
              style: TextStyle(
                fontSize: 15,
                color: theme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
