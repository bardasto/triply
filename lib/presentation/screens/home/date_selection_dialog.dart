import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/models/country_model.dart';

class DateSelectionDialog {
  static Future<void> show(
    BuildContext context, {
    required CountryModel country,
    required bool isDarkMode,
    required Function(DateTime, DateTime) onDatesSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _DateSelectionBottomSheet(
          country: country,
          isDarkMode: isDarkMode,
          onDatesSelected: onDatesSelected,
        );
      },
    );
  }
}

class _DateSelectionBottomSheet extends StatefulWidget {
  final CountryModel country;
  final bool isDarkMode;
  final Function(DateTime, DateTime) onDatesSelected;

  const _DateSelectionBottomSheet({
    required this.country,
    required this.isDarkMode,
    required this.onDatesSelected,
  });

  @override
  State<_DateSelectionBottomSheet> createState() =>
      _DateSelectionBottomSheetState();
}

class _DateSelectionBottomSheetState extends State<_DateSelectionBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _currentMonth = DateTime.now();

  SelectionState _selectionState = SelectionState.selectingStart;

  final List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  final Map<String, List<Color>> _continentGradients = {
    'Africa': [const Color(0xFFFF6B6B), const Color(0xFFEE5A6F)],
    'Asia': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    'Europe': [const Color(0xFF667eea), const Color(0xFF764ba2)],
    'North America': [const Color(0xFF667db6), const Color(0xFF0082c8)],
    'South America': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
    'Oceania': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
    'Antarctica': [const Color(0xFF89f7fe), const Color(0xFF66a6ff)],
  };

  bool get _isDark => widget.isDarkMode;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _surfaceColor =>
      _isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1D1D1D);
  Color get _textSecondary => _isDark ? Colors.white70 : Colors.grey[600]!;
  Color get _dividerColor => _isDark ? Colors.white12 : Colors.grey[300]!;
  Color get _closeButtonBg => _isDark ? Colors.white12 : Colors.grey[100]!;
  Color get _dayTextDisabled => _isDark ? Colors.white24 : Colors.grey[400]!;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    setState(() {
      switch (_selectionState) {
        case SelectionState.selectingStart:
          _startDate = date;
          _endDate = null;
          _selectionState = SelectionState.selectingEnd;
          break;

        case SelectionState.selectingEnd:
          if (date.isAfter(_startDate!) || date.isAtSameMomentAs(_startDate!)) {
            _endDate = date;
            _selectionState = SelectionState.completed;
          } else {
            _startDate = date;
            _endDate = null;
            _selectionState = SelectionState.selectingEnd;
          }
          break;

        case SelectionState.completed:
          _startDate = date;
          _endDate = null;
          _selectionState = SelectionState.selectingEnd;
          break;
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  bool _isDateInRange(DateTime date) {
    if (_startDate == null || _endDate == null) return false;
    return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  bool _isDateSelected(DateTime date) {
    return (_startDate != null && _isSameDay(date, _startDate!)) ||
        (_endDate != null && _isSameDay(date, _endDate!));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _confirm() {
    if (_startDate != null && _endDate != null) {
      Navigator.of(context).pop();
      widget.onDatesSelected(_startDate!, _endDate!);
    }
  }

  void _close() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}';
  }

  String _getSelectionText() {
    switch (_selectionState) {
      case SelectionState.selectingStart:
        return 'Select start date';
      case SelectionState.selectingEnd:
        return 'Select end date';
      case SelectionState.completed:
        return 'Tap to change dates';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, screenHeight * _slideAnimation.value),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 420,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDark ? 0.5 : 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCompactHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: _buildCompactCalendar(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: _buildImageCard(),
                                    ),
                                  ),
                                  if (_startDate != null && _endDate != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _buildDateBadge(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: _buildiPhoneStyleButtons(),
                    ),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).padding.bottom,
                width: double.infinity,
                color: _backgroundColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan your trip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSelectionText(),
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _closeButtonBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: _textSecondary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCalendar() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _previousMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isDark ? 0.3 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
                Text(
                  '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isDark ? 0.3 : 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _textSecondary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: _buildStaticCalendarGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final days = <Widget>[];

    for (int i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isPast =
          date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      final isSelected = _isDateSelected(date);
      final isInRange = _isDateInRange(date);

      days.add(
        GestureDetector(
          onTap: isPast ? null : () => _selectDate(date),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isInRange
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isPast
                      ? _dayTextDisabled
                      : isSelected
                          ? Colors.white
                          : _textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    while (days.length < 42) {
      days.add(const SizedBox());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: days,
    );
  }

  Widget _buildImageCard() {
    final imageUrl = widget.country.imageUrl;
    final gradient = _continentGradients[widget.country.continent] ??
        [const Color(0xFF667eea), const Color(0xFF764ba2)];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradient,
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildiPhoneStyleButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _close,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color:
                    _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isDark ? Colors.white70 : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _startDate != null && _endDate != null ? _confirm : null,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: _startDate != null && _endDate != null
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8)
                        ],
                      )
                    : null,
                color: _startDate == null || _endDate == null
                    ? (_isDark
                        ? const Color(0xFF3A3A3C)
                        : const Color(0xFFE5E5EA))
                    : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _startDate != null && _endDate != null
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _startDate != null && _endDate != null
                        ? Colors.white
                        : (_isDark ? Colors.white38 : const Color(0xFFAEAEB2)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum SelectionState {
  selectingStart,
  selectingEnd,
  completed,
}
