import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/trip_details_utils.dart';
import '../../place_details_screen.dart';
import '../common/bounceable_button.dart';
import '../common/context_menu.dart';
import '../common/context_menu_action.dart';

/// Card displaying a single restaurant with context menu on long press.
class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final Map<String, dynamic> trip;
  final bool isDark;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.trip,
    required this.isDark,
    this.onReplace,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TripDetailsTheme.of(isDark);
    final restaurantId =
        restaurant['poi_id']?.toString() ?? restaurant['name'];
    final category = restaurant['category'] as String? ?? 'restaurant';

    final cardContent = _buildCardContent(context, theme, category);

    // Build context menu actions
    final actions = <ContextMenuAction>[
      if (onReplace != null)
        ContextMenuAction(
          label: 'Replace',
          icon: CupertinoIcons.arrow_2_squarepath,
          onTap: onReplace!,
        ),
      if (onDelete != null)
        ContextMenuAction(
          label: 'Delete',
          icon: CupertinoIcons.trash,
          onTap: onDelete!,
          isDestructive: true,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ContextMenu(
        enabled: actions.isNotEmpty,
        actions: actions,
        preview: _buildPreviewCard(theme, category),
        child: Slidable(
          key: Key(restaurantId),
          endActionPane: _buildActionPane(),
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildPreviewCard(TripDetailsTheme theme, String category) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPreview(theme, category),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildCategoryBadge(category),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ActionPane? _buildActionPane() {
    if (onReplace == null && onDelete == null) return null;

    return ActionPane(
      motion: const BehindMotion(),
      extentRatio: 0.45,
      children: [
        if (onReplace != null)
          CustomSlidableAction(
            onPressed: (_) => onReplace!(),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                SizedBox(height: 6),
                Text(
                  'Replace',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (onDelete != null)
          CustomSlidableAction(
            onPressed: (context) async {
              onDelete!();
              if (context.mounted) {
                Slidable.of(context)?.close();
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, color: Colors.white, size: 24),
                SizedBox(height: 6),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCardContent(
      BuildContext context, TripDetailsTheme theme, String category) {
    return BounceableButton(
      onTap: () => _navigateToDetails(context),
      scaleFactor: 0.97,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: theme.cardDecoration,
        child: Row(
          children: [
            _buildPreview(theme, category),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(theme, category)),
            Icon(Icons.chevron_right, color: theme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(
          place: restaurant,
          trip: trip,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildPreview(TripDetailsTheme theme, String category) {
    final imageUrl = TripDetailsUtils.getImageUrl(restaurant);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TripDetailsTheme.radiusSmall),
        color: theme.surfaceColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  TripDetailsUtils.buildCategoryIconWidget(category,
                      isDark: isDark),
            )
          : TripDetailsUtils.buildCategoryIconWidget(category, isDark: isDark),
    );
  }

  Widget _buildInfo(TripDetailsTheme theme, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant['name'] as String,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
            decoration: TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildCategoryBadge(category),
            if (restaurant['rating'] != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                "${restaurant['rating']}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(String category) {
    final color = TripDetailsUtils.getCategoryColor(category);
    final label = TripDetailsUtils.getCategoryLabel(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
