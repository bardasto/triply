import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../../../../core/constants/color_constants.dart';
import '../../theme/trip_details_theme.dart';
import '../../utils/trip_details_utils.dart';
import '../../place_details_screen.dart';
import '../common/context_menu.dart';
import '../common/context_menu_action.dart';

/// Card displaying a single place with context menu on long press.
class PlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final Map<String, dynamic> trip;
  final bool isDark;
  final bool isSelected;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReplace;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onLongPress;

  const PlaceCard({
    super.key,
    required this.place,
    required this.trip,
    required this.isDark,
    this.isSelected = false,
    this.onEdit,
    this.onDelete,
    this.onReplace,
    this.onToggleSelection,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TripDetailsTheme.of(isDark);
    final placeId = TripDetailsUtils.getPlaceId(place);

    final cardContent = _buildCardContent(context, theme);

    // Build context menu actions
    final actions = <ContextMenuAction>[
      if (onEdit != null)
        ContextMenuAction(
          label: 'Edit',
          icon: CupertinoIcons.pencil,
          onTap: onEdit!,
          showsInput: true,
          inputPlaceholder: 'Describe changes...',
          onInputSubmit: (prompt) {
            // TODO: Handle GPT prompt for editing
            debugPrint('Edit prompt: $prompt');
          },
        ),
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
        preview: _buildPreviewCard(theme),
        child: Slidable(
          key: Key(placeId),
          endActionPane: _buildActionPane(),
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildPreviewCard(TripDetailsTheme theme) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: TripDetailsTheme.paddingCard,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPreview(theme),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildMetaInfo(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ActionPane? _buildActionPane() {
    if (onEdit == null && onDelete == null && onReplace == null) return null;

    // Calculate extent ratio based on number of actions
    final actionCount =
        (onEdit != null ? 1 : 0) +
        (onReplace != null ? 1 : 0) +
        (onDelete != null ? 1 : 0);
    final extentRatio = actionCount == 3 ? 0.6 : 0.45;

    return ActionPane(
      motion: const BehindMotion(),
      extentRatio: extentRatio,
      children: [
        if (onEdit != null)
          CustomSlidableAction(
            onPressed: (_) => onEdit!(),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.white, size: 22),
                SizedBox(height: 4),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        if (onReplace != null)
          CustomSlidableAction(
            onPressed: (_) => onReplace!(),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, color: Colors.white, size: 22),
                SizedBox(height: 4),
                Text(
                  'Replace',
                  style: TextStyle(
                    fontSize: 12,
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, color: Colors.white, size: 22),
                SizedBox(height: 4),
                Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildCardContent(BuildContext context, TripDetailsTheme theme) {
    return InkWell(
      borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
      onTap: () => _navigateToDetails(context),
      child: Container(
        padding: TripDetailsTheme.paddingCard,
        decoration: theme.selectedCardDecoration(isSelected: isSelected),
        child: Row(
          children: [
            _buildPreview(theme),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(theme)),
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(
          place: place,
          trip: trip,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildPreview(TripDetailsTheme theme) {
    final imageUrl = TripDetailsUtils.getImageUrl(place);
    final category = place['category'] as String? ?? 'attraction';

    return Container(
      width: 48,
      height: 48,
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
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
            )
          : TripDetailsUtils.buildCategoryIconWidget(category, isDark: isDark),
    );
  }

  Widget _buildInfo(TripDetailsTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          place['name'] as String,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _buildMetaInfo(),
      ],
    );
  }

  Widget _buildMetaInfo() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (place['rating'] != null) _buildRating(),
        if (place['price'] != null) _buildPrice(),
        if (place['duration_minutes'] != null) _buildDuration(),
      ],
    );
  }

  Widget _buildRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 2),
        Text(
          "${place['rating']}",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.amber,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.euro, color: Colors.green, size: 13),
        const SizedBox(width: 2),
        Text(
          place['price'],
          style: const TextStyle(
            fontSize: 13,
            color: Colors.green,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildDuration() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time, color: Colors.blue, size: 13),
        const SizedBox(width: 2),
        Text(
          '${place['duration_minutes']} min',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.blue,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(TripDetailsTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        Icon(Icons.chevron_right, color: theme.textSecondary, size: 22),
      ],
    );
  }
}
