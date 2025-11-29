import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/search_theme.dart';
import 'calendar_month.dart';

/// Expanded content for the When section with calendar.
class WhenExpandedContent extends StatefulWidget {
  final DateTimeRange? selectedDateRange;
  final ValueChanged<DateTimeRange> onDateRangeSelected;

  const WhenExpandedContent({
    super.key,
    required this.selectedDateRange,
    required this.onDateRangeSelected,
  });

  @override
  State<WhenExpandedContent> createState() => _WhenExpandedContentState();
}

class _WhenExpandedContentState extends State<WhenExpandedContent> {
  DateTime? _startDate;
  DateTime? _endDate;

  void _onDateSelected(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        if (date.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
        widget.onDateRangeSelected(
          DateTimeRange(start: _startDate!, end: _endDate!),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: SearchTheme.calendarDayLabelStyle,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar
          SizedBox(
            height: 320,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CalendarMonth(
                    month: 'December 2025',
                    year: 2025,
                    monthNumber: 12,
                    daysInMonth: 31,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 20),
                  CalendarMonth(
                    month: 'January 2026',
                    year: 2026,
                    monthNumber: 1,
                    daysInMonth: 31,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 20),
                  CalendarMonth(
                    month: 'February 2026',
                    year: 2026,
                    monthNumber: 2,
                    daysInMonth: 28,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
