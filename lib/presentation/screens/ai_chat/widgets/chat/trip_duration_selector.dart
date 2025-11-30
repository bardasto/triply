import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/color_constants.dart';
import '../../theme/ai_chat_theme.dart';

/// A minimalist widget for selecting trip duration and travelers.
class TripDurationSelector extends StatefulWidget {
  final String cityName;
  final Function(int days, {int? travelers, DateTime? startDate}) onDurationSelected;

  const TripDurationSelector({
    super.key,
    required this.cityName,
    required this.onDurationSelected,
  });

  @override
  State<TripDurationSelector> createState() => _TripDurationSelectorState();
}

class _TripDurationSelectorState extends State<TripDurationSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isDurationExpanded = false;
  bool _isTravelersExpanded = false;
  int _selectedDays = 3;
  int _adults = 2;
  int _children = 0;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  late DateTime _currentMonth;

  // Spacing between sections
  static const double _sectionSpacing = 8.0;
  // Duration takes 65% of width, Travelers takes 35%
  static const double _durationFlex = 0.65;
  static const double _travelersFlex = 0.35;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
    _animationController.forward();
  }

  void _previousMonth() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final minMonth = DateTime(now.year, now.month, 1);
    final prevMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    if (!prevMonth.isBefore(minMonth)) {
      setState(() => _currentMonth = prevMonth);
    }
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onDurationTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isDurationExpanded = !_isDurationExpanded;
      if (_isDurationExpanded) {
        _isTravelersExpanded = false;
      }
    });
  }

  void _onTravelersTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isTravelersExpanded = !_isTravelersExpanded;
      if (_isTravelersExpanded) {
        _isDurationExpanded = false;
      }
    });
  }

  void _onDateTapped(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedStartDate == null) {
        // First tap - select start date
        _selectedStartDate = date;
        _selectedEndDate = null;
      } else if (_selectedEndDate == null) {
        // Second tap - select end date
        if (date.isBefore(_selectedStartDate!)) {
          // If tapped date is before start, make it the new start
          _selectedEndDate = _selectedStartDate;
          _selectedStartDate = date;
        } else if (date.isAtSameMomentAs(_selectedStartDate!)) {
          // If same date tapped, reset selection
          _selectedStartDate = null;
          _selectedEndDate = null;
        } else {
          _selectedEndDate = date;
        }
        // Calculate days when we have both dates
        if (_selectedStartDate != null && _selectedEndDate != null) {
          _selectedDays = _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
        }
      } else {
        // Both dates selected - start new selection
        _selectedStartDate = date;
        _selectedEndDate = null;
      }
    });
  }

  int get _totalTravelers => _adults + _children;

  void _incrementAdults() {
    HapticFeedback.selectionClick();
    setState(() => _adults++);
  }

  void _decrementAdults() {
    if (_adults > 1) {
      HapticFeedback.selectionClick();
      setState(() => _adults--);
    }
  }

  void _incrementChildren() {
    HapticFeedback.selectionClick();
    setState(() => _children++);
  }

  void _decrementChildren() {
    if (_children > 0) {
      HapticFeedback.selectionClick();
      setState(() => _children--);
    }
  }

  void _onLetsGo() {
    HapticFeedback.mediumImpact();
    widget.onDurationSelected(
      _selectedDays,
      travelers: _totalTravelers,
      startDate: _selectedStartDate,
    );
  }

  String _formatDateRange() {
    if (_selectedStartDate == null) {
      return 'Flexible';
    }
    if (_selectedEndDate == null) {
      // Only start date selected
      return '${_selectedStartDate!.day}/${_selectedStartDate!.month} - ...';
    }
    return '${_selectedStartDate!.day}/${_selectedStartDate!.month} - ${_selectedEndDate!.day}/${_selectedEndDate!.month}';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: AiChatTheme.messageWidthFactor,
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final durationWidth = (totalWidth - _sectionSpacing) * _durationFlex;
                final travelersWidth = (totalWidth - _sectionSpacing) * _travelersFlex;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration and Travelers in one row
                    Row(
                      children: [
                        // Duration (wider)
                        SizedBox(
                          width: durationWidth,
                          child: _buildCompactSection(
                            title: 'When',
                            value: _formatDateRange(),
                            isExpanded: _isDurationExpanded,
                            onTap: _onDurationTap,
                          ),
                        ),
                        const SizedBox(width: _sectionSpacing),
                        // Travelers (narrower)
                        SizedBox(
                          width: travelersWidth,
                          child: _buildCompactSection(
                            title: 'Travelers',
                            value: '$_totalTravelers',
                            isExpanded: _isTravelersExpanded,
                            onTap: _onTravelersTap,
                          ),
                        ),
                      ],
                    ),
                    // Dropdowns row - each aligned under its button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Duration dropdown (calendar)
                        SizedBox(
                          width: durationWidth,
                          child: _isDurationExpanded
                              ? _buildCalendarDropdown()
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: _sectionSpacing),
                        // Travelers dropdown
                        SizedBox(
                          width: travelersWidth,
                          child: _isTravelersExpanded
                              ? _buildTravelersDropdown()
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Let's Go button (full width)
                    _buildLetsGoButton(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSection({
    required String title,
    required String value,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151517),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: 0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF151517),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: _buildMiniCalendar(),
      ),
    );
  }

  Widget _buildMiniCalendar() {
    final now = DateTime.now();
    final canGoPrev = !DateTime(_currentMonth.year, _currentMonth.month - 1, 1)
        .isBefore(DateTime(now.year, now.month, 1));

    return Column(
      children: [
        // Month header with navigation arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: canGoPrev ? _previousMonth : null,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_left,
                  color: canGoPrev
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  size: 20,
                ),
              ),
            ),
            Text(
              '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            GestureDetector(
              onTap: _nextMonth,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        _buildCalendarGrid(_currentMonth, now),
        const SizedBox(height: 12),
        // Divider
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 12),
        // Flexible dates option
        _buildFlexibleOption(),
      ],
    );
  }

  Widget _buildFlexibleOption() {
    final isFlexible = _selectedStartDate == null && _selectedEndDate == null;
    final hasDateRange = _selectedStartDate != null && _selectedEndDate != null;

    // Show "Done" when date range is selected, otherwise "I'm flexible"
    final buttonText = hasDateRange ? "Done" : "I'm flexible";
    final isActive = isFlexible || hasDateRange;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (hasDateRange) {
          // Close the calendar dropdown when "Done" is tapped
          setState(() {
            _isDurationExpanded = false;
          });
        } else {
          // Reset to flexible dates
          setState(() {
            _selectedStartDate = null;
            _selectedEndDate = null;
            _selectedDays = 3; // Reset to default
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : const Color(0xFF0A0A0C),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime month, DateTime now) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    int startWeekday = firstDayOfMonth.weekday - 1;
    if (startWeekday < 0) startWeekday = 6;

    // Build rows of 7 days each
    final List<Widget> rows = [];
    List<Widget> currentRow = [];

    // Empty cells for days before month starts
    for (int i = 0; i < startWeekday; i++) {
      currentRow.add(Expanded(child: Container(height: 36)));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isBeforeToday = date.isBefore(DateTime(now.year, now.month, now.day));

      // Check if this date is the start date
      final isStartDate = _selectedStartDate != null &&
          date.year == _selectedStartDate!.year &&
          date.month == _selectedStartDate!.month &&
          date.day == _selectedStartDate!.day;

      // Check if this date is the end date
      final isEndDate = _selectedEndDate != null &&
          date.year == _selectedEndDate!.year &&
          date.month == _selectedEndDate!.month &&
          date.day == _selectedEndDate!.day;

      // Check if this date is in the range between start and end
      final isInRange = _selectedStartDate != null &&
          _selectedEndDate != null &&
          date.isAfter(_selectedStartDate!) &&
          date.isBefore(_selectedEndDate!);

      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: isBeforeToday ? null : () => _onDateTapped(date),
            child: Container(
              height: 36,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: (isStartDate || isEndDate)
                    ? AppColors.primary
                    : isInRange
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isBeforeToday
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.white,
                    fontSize: 14,
                    fontWeight: (isStartDate || isEndDate) ? FontWeight.w700 : FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // If row is complete (7 days) or last day
      if (currentRow.length == 7) {
        rows.add(Row(children: currentRow));
        currentRow = [];
      }
    }

    // Fill remaining cells in the last row
    while (currentRow.isNotEmpty && currentRow.length < 7) {
      currentRow.add(Expanded(child: Container(height: 36)));
    }
    if (currentRow.isNotEmpty) {
      rows.add(Row(children: currentRow));
    }

    return Column(children: rows);
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildTravelersDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151517),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Adults section
            _buildCounterSection(
              label: 'Adults',
              value: _adults,
              onIncrement: _incrementAdults,
              onDecrement: _decrementAdults,
              canDecrement: _adults > 1,
            ),
            const SizedBox(height: 12),
            // Divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            // Children section
            _buildCounterSection(
              label: 'Children',
              value: _children,
              onIncrement: _incrementChildren,
              onDecrement: _decrementChildren,
              canDecrement: _children > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterSection({
    required String label,
    required int value,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required bool canDecrement,
  }) {
    return Column(
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 6),
        // Counter controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minus button
            GestureDetector(
              onTap: canDecrement ? onDecrement : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: canDecrement
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.remove,
                    color: canDecrement
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.2),
                    size: 16,
                  ),
                ),
              ),
            ),
            // Value
            SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            // Plus button
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLetsGoButton() {
    return GestureDetector(
      onTap: _onLetsGo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "Let's Go!",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
