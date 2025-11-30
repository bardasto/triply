import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../models/chat_history.dart';

/// A widget representing a single history item in the sidebar.
class HistoryItem extends StatefulWidget {
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

  @override
  State<HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<HistoryItem> {
  bool _hasTriggeredHaptic = false;

  IconData _getModeIcon() {
    switch (widget.history.mode.name) {
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
                widget.onDelete();
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

  void _onSlideChanged(double ratio) {
    // Trigger haptic when delete button becomes visible (ratio > 0)
    if (ratio > 0.1 && !_hasTriggeredHaptic) {
      HapticFeedback.lightImpact();
      _hasTriggeredHaptic = true;
    } else if (ratio <= 0.05) {
      // Reset when slide is closed
      _hasTriggeredHaptic = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Slidable(
        key: ValueKey(widget.history.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.2,
          // Enable dismiss on full swipe
          dismissible: DismissiblePane(
            onDismissed: () {
              HapticFeedback.mediumImpact();
              widget.onDelete();
            },
            closeOnCancel: true,
            dismissalDuration: const Duration(milliseconds: 150),
          ),
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                HapticFeedback.mediumImpact();
                widget.onDelete();
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              child: const Icon(Icons.delete_outline, size: 22),
            ),
          ],
        ),
        child: Builder(
          builder: (context) {
            // Listen to slidable animation
            final controller = Slidable.of(context);
            controller?.animation.addListener(() {
              _onSlideChanged(controller.animation.value);
            });

            return GestureDetector(
              onTap: widget.onTap,
              onLongPress: () => _showDeleteMenu(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: widget.isSelected ? AppColors.primary : Colors.transparent,
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
                      color: widget.isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.history.title,
                            style: TextStyle(
                              color: widget.isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight:
                                  widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.formatDate(widget.history.updatedAt),
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
            );
          },
        ),
      ),
    );
  }
}
