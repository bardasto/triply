import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

class DateSelectionDialog {
  static Future<void> show(
    BuildContext context, {
    required String country,
    required String city,
    required Function(DateTime, DateTime) onDatesSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _DateSelectionBottomSheet(
          country: country,
          city: city,
          onDatesSelected: onDatesSelected,
        );
      },
    );
  }
}

class _DateSelectionBottomSheet extends StatefulWidget {
  final String country;
  final String city;
  final Function(DateTime, DateTime) onDatesSelected;

  const _DateSelectionBottomSheet({
    required this.country,
    required this.city,
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

  // ✅ КАРТА ИЗОБРАЖЕНИЙ ДЛЯ ГОРОДОВ
  final Map<String, String> _cityImages = {
    'Rio de Janeiro':
        'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'Santorini':
        'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'Rome':
        'https://images.unsplash.com/photo-1552832230-c0197dd311b5?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'Paris':
        'https://images.unsplash.com/photo-1502602898536-47ad22581b52?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'Tokyo':
        'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'Athens':
        'https://images.unsplash.com/photo-1555993539-1732b0258235?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'Barcelona':
        'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'London':
        'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
    'New York':
        'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
  };

  // ✅ Карты градиентов как fallback
  final Map<String, List<Color>> _countryGradients = {
    'Brazil': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
    'Italy': [const Color(0xFFFF8A80), const Color(0xFFFF5722)],
    'France': [const Color(0xFF667eea), const Color(0xFF764ba2)],
    'Japan': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    'Greece': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
    'Spain': [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
    'UK': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
    'USA': [const Color(0xFF667db6), const Color(0xFF0082c8)],
  };

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
    final months = [
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
    return '${months[date.month - 1]} ${date.day}';
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
              // ✅ ОСНОВНОЕ ДИАЛОГОВОЕ ОКНО
              Container(
                height: 420,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ✅ КОМПАКТНЫЙ HEADER
                    _buildCompactHeader(),

                    // ✅ ОСНОВНОЙ КОНТЕНТ БЕЗ АНИМАЦИЙ
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            // ✅ СТАТИЧЕСКИЙ КАЛЕНДАРЬ
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

                            // ✅ СТАТИЧЕСКАЯ КАРТОЧКА С ФОТО
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: _buildImageCard(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ✅ КНОПКИ
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: _buildiPhoneStyleButtons(),
                    ),
                  ],
                ),
              ),

              // ✅ БЕЛАЯ ПОЛОСА ВНИЗУ
              Container(
                height: MediaQuery.of(context).padding.bottom,
                width: double.infinity,
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ КОМПАКТНЫЙ HEADER
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 12),

          // Заголовок и кнопка закрытия
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan your trip',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSelectionText(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
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
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.grey[600],
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

  // ✅ СТАТИЧЕСКИЙ КАЛЕНДАРЬ С БОЛЬШИМИ ДНЯМИ
  Widget _buildCompactCalendar() {
    return Container(
      height: 250, // ✅ ФИКСИРОВАННАЯ ВЫСОТА
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header календаря
          Container(
            padding: const EdgeInsets.all(10), // ✅ Чуть больше padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _previousMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8), // ✅ Больше padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.primary,
                      size: 18, // ✅ Больше иконка
                    ),
                  ),
                ),
                Text(
                  '${_monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 15, // ✅ Больше шрифт
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1D),
                  ),
                ),
                GestureDetector(
                  onTap: _nextMonth,
                  child: Container(
                    padding: const EdgeInsets.all(8), // ✅ Больше padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 18, // ✅ Больше иконка
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Дни недели
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12, // ✅ Больше шрифт
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // ✅ СТАТИЧЕСКАЯ КАЛЕНДАРНАЯ СЕТКА
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

  // ✅ СТАТИЧЕСКАЯ СЕТКА КАЛЕНДАРЯ С БОЛЬШИМИ ДНЯМИ
  Widget _buildStaticCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final days = <Widget>[];

    // Пустые ячейки
    for (int i = 0; i < firstWeekday; i++) {
      days.add(const SizedBox());
    }

    // Дни месяца
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
            margin: const EdgeInsets.all(1), // ✅ Чуть больше margin
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isInRange
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(6), // ✅ Больше радиус
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  fontSize: 13, // ✅ БОЛЬШЕ ШРИФТ ДЛЯ ДНЕЙ
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isPast
                      ? Colors.grey[400]
                      : isSelected
                          ? Colors.white
                          : const Color(0xFF1D1D1D),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ✅ Дополняем пустыми ячейками до полных 42 ячеек (6 недель)
    while (days.length < 42) {
      days.add(const SizedBox());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0, // ✅ КВАДРАТНЫЕ ЯЧЕЙКИ
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: days,
    );
  }

  // ✅ КАРТОЧКА С ФОТО (ОДИНАКОВАЯ ВЫСОТА С КАЛЕНДАРЕМ)
  Widget _buildImageCard() {
    final imageUrl = _cityImages[widget.city];
    final gradient = _countryGradients[widget.country] ??
        [const Color(0xFF667eea), const Color(0xFF764ba2)];

    return Container(
      height: 250, // ✅ ТА ЖЕ ВЫСОТА ЧТО И КАЛЕНДАРЬ
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
            // ✅ ФОТОГРАФИЯ ГОРОДА ИЛИ ГРАДИЕНТ КАК FALLBACK
            if (imageUrl != null)
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
              // Fallback градиент если нет изображения
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),

            // ✅ ТЕМНЫЙ OVERLAY ДЛЯ ЧИТАЕМОСТИ ТЕКСТА
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // ✅ КОНТЕНТ ПОВЕРХ ФОТОГРАФИИ
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.city,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  if (_startDate != null && _endDate != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                        style: const TextStyle(
                          color: Color(0xFF1D1D1D),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ КНОПКИ
  Widget _buildiPhoneStyleButtons() {
    return Row(
      children: [
        // Cancel button
        Expanded(
          child: GestureDetector(
            onTap: _close,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Continue button
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
                    ? const Color(0xFFE5E5EA)
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
                        : const Color(0xFFAEAEB2),
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
