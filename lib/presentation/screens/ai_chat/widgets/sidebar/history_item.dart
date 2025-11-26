import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../models/chat_history.dart';

/// A widget representing a single history item in the sidebar.
class HistoryItem extends StatelessWidget {
  final ChatHistory history;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String Function(DateTime) formatDate;

  const HistoryItem({
    super.key,
    required this.history,
    this.isSelected = false,
    required this.onTap,
    required this.onDelete,
    required this.formatDate,
  });

  IconData _getModeIcon() {
    switch (history.mode.name) {
      case 'tripGeneration':
        return Icons.flight_takeoff;
      case 'hotelSelection':
        return Icons.hotel;
      case 'flightTickets':
        return Icons.airplane_ticket;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  void _showDeleteMenu(BuildContext context) {
    HapticFeedback.mediumImpact();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
        ),
        child: CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                onDelete();
              },
              child: const Text('Delete Chat'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Slidable(
        key: ValueKey(history.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.2,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                onDelete();
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              child: const Icon(Icons.delete_outline, size: 22),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: () => _showDeleteMenu(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getModeIcon(),
                  size: 18,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history.title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDate(history.updatedAt),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
