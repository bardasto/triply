import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../providers/trip_provider.dart';
import '../../../../core/data/repositories/city_repository.dart';
import '../../../../core/models/city_model.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/trip_model.dart';
import '../../city_trips/city_trips_screen.dart';

class SearchModal extends StatefulWidget {
  const SearchModal({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const SearchModal(),
    );
  }

  @override
  State<SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<SearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CityRepository _cityRepository = CityRepository();

  bool _isWhenExpanded = false;
  bool _isExpanded = false; // Controls sheet height
  DateTimeRange? _selectedDateRange;

  List<CityModel> _filteredSuggestions = [];
  bool _showSuggestions = false;
  bool _isLoadingSuggestions = false;
  bool _isProgrammaticChange = false;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _focusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_isProgrammaticChange) return;

    final query = _searchController.text.trim();
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filteredSuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchCities(query);
    });
  }

  Future<void> _searchCities(String query) async {
    try {
      final cities = await _cityRepository.searchCities(
        query: query,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _filteredSuggestions = cities;
          _showSuggestions = cities.isNotEmpty;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching cities: $e');
      if (mounted) {
        setState(() {
          _filteredSuggestions = [];
          _showSuggestions = false;
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  void _selectSuggestion(CityModel city) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();

    setState(() {
      _isProgrammaticChange = true;
      _searchController.text = city.name;
      _showSuggestions = false;
      _filteredSuggestions = [];
      _isLoadingSuggestions = false;
      _isWhenExpanded = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _isProgrammaticChange = false;
    });
  }

  void _performSearch() {
    if (_searchController.text.isEmpty) return;

    final cityName = _searchController.text.trim();
    final tripProvider = context.read<TripProvider>();

    final allTrips = tripProvider.nearbyTrips;
    final cityTrips = allTrips.where((trip) {
      if (trip is Trip) {
        return trip.city?.toLowerCase() == cityName.toLowerCase();
      } else if (trip is TripModel) {
        return trip.city?.toLowerCase() == cityName.toLowerCase();
      }
      return false;
    }).toList();

    Navigator.of(context).pop();

    if (cityTrips.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CityTripsScreen(
            cityName: cityName,
            trips: cityTrips,
            isDarkMode: true,
          ),
        ),
      );
    }
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _searchController.clear();
      _selectedDateRange = null;
      _showSuggestions = false;
      _filteredSuggestions = [];
      _isWhenExpanded = false;
    });
    final tripProvider = context.read<TripProvider>();
    tripProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Compact height: ~380px for basic elements, expanded: 85%
    final compactHeight = 380.0 + bottomPadding;
    final expandedHeight = screenHeight * 0.85;
    final sheetHeight = _isExpanded || keyboardHeight > 0 ? expandedHeight : compactHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: keyboardHeight + bottomPadding + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search field
                    _buildSearchField(),

                    // Suggestions dropdown
                    if (_showSuggestions || _isLoadingSuggestions) ...[
                      const SizedBox(height: 12),
                      _buildSuggestionsContainer(),
                    ],

                    // Spacing after search field when city is selected
                    if (!_showSuggestions && !_isLoadingSuggestions &&
                        _searchController.text.trim().isNotEmpty)
                      const SizedBox(height: 12),

                    // Recent searches section
                    if (!_showSuggestions && !_isLoadingSuggestions &&
                        _searchController.text.trim().isEmpty) ...[
                      const SizedBox(height: 12),
                      _buildRecentSearches(),
                    ],

                    const SizedBox(height: 12),

                    // When section
                    _buildWhenSection(),

                    const SizedBox(height: 12),

                    // Bottom buttons
                    _buildBottomButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        autofocus: false,
        keyboardAppearance: Brightness.dark,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
        ),
        decoration: InputDecoration(
          hintText: 'Search destinations',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 17,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withValues(alpha: 0.5),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _searchController.clear();
                      _showSuggestions = false;
                      _filteredSuggestions = [];
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildSuggestionsContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoadingSuggestions
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredSuggestions.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
                indent: 56,
              ),
              itemBuilder: (context, index) {
                final suggestion = _filteredSuggestions[index];
                return _SuggestionItem(
                  city: suggestion,
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
    );
  }

  Widget _buildRecentSearches() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _RecentSearchItem(
            icon: Icons.location_city,
            title: 'Barcelona',
            subtitle: 'Spain',
            onTap: () {
              _searchController.text = 'Barcelona';
              _performSearch();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWhenSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              FocusScope.of(context).unfocus();
              setState(() {
                _isWhenExpanded = !_isWhenExpanded;
                if (_isWhenExpanded) {
                  _isExpanded = true;
                }
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'When',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _selectedDateRange == null
                          ? 'Add dates'
                          : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isWhenExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isWhenExpanded)
            _WhenExpandedContent(
              selectedDateRange: _selectedDateRange,
              onDateRangeSelected: (range) {
                setState(() {
                  _selectedDateRange = range;
                  _isWhenExpanded = false;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _clearAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Clear all',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 18),
                SizedBox(width: 6),
                Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// When expanded content widget
class _WhenExpandedContent extends StatefulWidget {
  final DateTimeRange? selectedDateRange;
  final Function(DateTimeRange) onDateRangeSelected;

  const _WhenExpandedContent({
    required this.selectedDateRange,
    required this.onDateRangeSelected,
  });

  @override
  State<_WhenExpandedContent> createState() => _WhenExpandedContentState();
}

class _WhenExpandedContentState extends State<_WhenExpandedContent> {
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
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
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
                  _CalendarMonth(
                    month: 'December 2025',
                    year: 2025,
                    monthNumber: 12,
                    daysInMonth: 31,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 20),
                  _CalendarMonth(
                    month: 'January 2026',
                    year: 2026,
                    monthNumber: 1,
                    daysInMonth: 31,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 20),
                  _CalendarMonth(
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

// Calendar month widget
class _CalendarMonth extends StatelessWidget {
  final String month;
  final int year;
  final int monthNumber;
  final int daysInMonth;
  final Function(DateTime) onDateSelected;
  final DateTime? startDate;
  final DateTime? endDate;

  const _CalendarMonth({
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.transparent
                      : (isStartDate || isEndDate)
                          ? AppColors.primary
                          : isInRange
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: (isStartDate || isEndDate)
                          ? FontWeight.w700
                          : FontWeight.w500,
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

class _RecentSearchItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecentSearchItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final CityModel city;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.city,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    city.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.country,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
