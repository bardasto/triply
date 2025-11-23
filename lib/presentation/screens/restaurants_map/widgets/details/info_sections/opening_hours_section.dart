import 'package:flutter/material.dart';
import '../../../utils/opening_hours_helper.dart';

/// Opening Hours Section widget
class OpeningHoursSection extends StatefulWidget {
  final dynamic openingHours;

  const OpeningHoursSection({
    super.key,
    required this.openingHours,
  });

  @override
  State<OpeningHoursSection> createState() => _OpeningHoursSectionState();
}

class _OpeningHoursSectionState extends State<OpeningHoursSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final openingStatus = OpeningHoursHelper.getOpeningStatus(widget.openingHours);
    final weekdayHours = OpeningHoursHelper.getWeekdayHours(widget.openingHours);
    final hasHours = weekdayHours.isNotEmpty;

    Color iconColor;
    Color textColor;
    if (openingStatus.toLowerCase().contains('closed')) {
      iconColor = Colors.red;
      textColor = Colors.red;
    } else if (openingStatus.toLowerCase().contains('open')) {
      iconColor = Colors.green;
      textColor = Colors.green;
    } else {
      iconColor = Colors.white70;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: hasHours
          ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    openingStatus,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (hasHours)
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 24,
                  ),
              ],
            ),
            if (_isExpanded && hasHours) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF3C3C3E)),
              const SizedBox(height: 12),
              ...weekdayHours.map((dayHours) {
                final parts = dayHours.split(':');
                final day = parts[0].trim();
                final hours =
                    parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        hours,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
