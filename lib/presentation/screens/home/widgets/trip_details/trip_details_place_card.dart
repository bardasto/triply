import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../../core/constants/color_constants.dart';
import '../place_details_screen.dart';
import 'trip_details_utils.dart';

class TripDetailsPlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final Map<String, dynamic> trip;
  final bool isDark;
  final bool isSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onLongPress;

  const TripDetailsPlaceCard({
    super.key,
    required this.place,
    required this.trip,
    required this.isDark,
    this.isSelected = false,
    this.onEdit,
    this.onDelete,
    this.onToggleSelection,
    this.onLongPress,
  });

  Color get _textPrimary => isDark ? Colors.white : AppColors.text;
  Color get _textSecondary => isDark ? Colors.white70 : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final placeId = place['poi_id']?.toString() ?? place['name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(placeId),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.45,
          children: [
            if (onEdit != null)
              CustomSlidableAction(
                onPressed: (_) => onEdit!(),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 24),
                    SizedBox(height: 6),
                    Text(
                      'Edit',
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
        child: GestureDetector(
          onLongPress: onLongPress,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceDetailsScreen(
                    place: place,
                    trip: trip,
                    isDark: isDark,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey[50]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.grey[200]!),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  _buildPlacePreview(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _buildPlaceInfo(),
                      ],
                    ),
                  ),
                  if (place['image_url'] != null && onToggleSelection != null)
                    IconButton(
                      icon: const Icon(Icons.photo, size: 19),
                      color: isSelected ? AppColors.primary : Colors.blueAccent,
                      onPressed: onToggleSelection,
                      tooltip: isSelected ? 'Remove filter' : 'Filter photos',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: _textSecondary, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacePreview() {
    final imageUrl = TripDetailsUtils.getImageUrl(place);
    final category = place['category'] as String? ?? 'attraction';

    return Container(
      width: 48,
      height: 48,
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
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
            )
          : TripDetailsUtils.buildCategoryIconWidget(category, isDark: isDark),
    );
  }

  Widget _buildPlaceInfo() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (place['rating'] != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  "${place['rating']}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (place['price'] != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.euro, color: Colors.green, size: 13),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  place['price'],
                  style: const TextStyle(fontSize: 13, color: Colors.green),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        if (place['duration_minutes'] != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, color: Colors.blue, size: 13),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  '${place['duration_minutes']} min',
                  style: const TextStyle(fontSize: 13, color: Colors.blue),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
