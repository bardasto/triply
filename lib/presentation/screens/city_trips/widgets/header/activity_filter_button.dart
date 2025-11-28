import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../models/activity_item.dart';

class ActivityFilterButton extends StatelessWidget {
  final bool hasActiveFilter;
  final List<ActivityItem>? selectedActivities;
  final VoidCallback onPressed;
  final bool embedded;

  const ActivityFilterButton({
    super.key,
    required this.hasActiveFilter,
    required this.selectedActivities,
    required this.onPressed,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final firstActivity =
        selectedActivities?.isNotEmpty == true ? selectedActivities!.first : null;
    final activityCount = selectedActivities?.length ?? 0;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: hasActiveFilter ? 12 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: hasActiveFilter
              ? firstActivity?.color.withValues(alpha: 0.85) ?? AppColors.primary
              : embedded
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasActiveFilter
                  ? firstActivity?.icon ?? PhosphorIconsBold.funnel
                  : PhosphorIconsBold.funnel,
              color: Colors.white,
              size: 18,
            ),
            if (hasActiveFilter && activityCount > 0) ...[
              const SizedBox(width: 6),
              Text(
                activityCount == 1 ? firstActivity!.label : '$activityCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
