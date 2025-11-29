import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

/// Calendar month widget for date selection.
class CalendarMonth extends StatelessWidget {
  final String month;
  final int year;
  final int monthNumber;
  final int daysInMonth;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? startDate;
  final DateTime? endDate;

  const CalendarMonth({
    super.key,
    required this.month,
    required this.year,
    required this.monthNumber,
    required this.daysInMonth,
    required this.onDateSelected,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(year, monthNumber, 1);
    final weekdayOffset = firstDayOfMonth.weekday - 1;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            month,
            style: SearchTheme.calendarMonthStyle,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: daysInMonth + weekdayOffset,
          itemBuilder: (context, index) {
            if (index < weekdayOffset) {
              return const SizedBox.shrink();
            }

            final day = index - weekdayOffset + 1;
            final currentDate = DateTime(year, monthNumber, day);
            final isDisabled = currentDate.isBefore(DateTime(today.year, today.month, today.day));

            final isStartDate = startDate != null &&
                currentDate.year == startDate!.year &&
                currentDate.month == startDate!.month &&
                currentDate.day == startDate!.day;

            final isEndDate = endDate != null &&
                currentDate.year == endDate!.year &&
                currentDate.month == endDate!.month &&
                currentDate.day == endDate!.day;

            final isInRange = startDate != null &&
                endDate != null &&
                currentDate.isAfter(startDate!) &&
                currentDate.isBefore(endDate!);

            return GestureDetector(
              onTap: isDisabled ? null : () => onDateSelected(currentDate),
              child: Container(
                decoration: SearchTheme.calendarDayDecoration(
                  isDisabled: isDisabled,
                  isStartDate: isStartDate,
                  isEndDate: isEndDate,
                  isInRange: isInRange,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: SearchTheme.calendarDayStyle(
                      isDisabled: isDisabled,
                      isSelected: isStartDate || isEndDate,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
