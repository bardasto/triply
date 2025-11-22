import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../../core/constants/color_constants.dart';
import '../place_details_screen.dart';
import 'trip_details_utils.dart';

class TripDetailsRestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final Map<String, dynamic> trip;
  final bool isDark;
  final VoidCallback? onReplace;
  final VoidCallback? onDelete;

  const TripDetailsRestaurantCard({
    super.key,
    required this.restaurant,
    required this.trip,
    required this.isDark,
    this.onReplace,
    this.onDelete,
  });

  Color get _textPrimary => isDark ? Colors.white : AppColors.text;
  Color get _textSecondary => isDark ? Colors.white70 : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final restaurantId = restaurant['poi_id']?.toString() ?? restaurant['name'];
    final imageUrl = TripDetailsUtils.getImageUrl(restaurant);
    final category = restaurant['category'] as String? ?? 'restaurant';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(restaurantId),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.45,
          children: [
            if (onReplace != null)
              CustomSlidableAction(
                onPressed: (_) => onReplace!(),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            if (onDelete != null)
              CustomSlidableAction(
                onPressed: (context) async {
                  onDelete!();
                  if (context.mounted) {
                    final slidableState = Slidable.of(context);
                    slidableState?.close();
                  }
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaceDetailsScreen(
                  place: restaurant,
                  trip: trip,
                  isDark: isDark,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildRestaurantPreview(imageUrl, category),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRestaurantInfo(category),
                ),
                Icon(Icons.chevron_right, color: _textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantPreview(String? imageUrl, String category) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[100],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  TripDetailsUtils.buildCategoryIconWidget(category, isDark: isDark),
            )
          : TripDetailsUtils.buildCategoryIconWidget(category, isDark: isDark),
    );
  }

  Widget _buildRestaurantInfo(String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant['name'] as String,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: TripDetailsUtils.getCategoryColor(category)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                TripDetailsUtils.getCategoryLabel(category),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: TripDetailsUtils.getCategoryColor(category),
                ),
              ),
            ),
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
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
