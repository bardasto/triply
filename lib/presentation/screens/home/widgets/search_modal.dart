import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
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
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SearchModal();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
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
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Skip if this is a programmatic change
    if (_isProgrammaticChange) {
      return;
    }

    final query = _searchController.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filteredSuggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    // Show loading immediately
    setState(() {
      _isLoadingSuggestions = true;
    });

    // Debounce: wait 300ms before searching
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
      print('Error searching cities: $e');
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
    // Close keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      // Set flag to prevent _onSearchChanged from triggering
      _isProgrammaticChange = true;
      _searchController.text = city.name;
      _showSuggestions = false;
      _filteredSuggestions = [];
      _isLoadingSuggestions = false;
      // Automatically expand "When" section
      _isWhenExpanded = true;
    });

    // Reset flag after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _isProgrammaticChange = false;
    });
  }

  void _performSearch() {
    if (_searchController.text.isEmpty) return;

    final cityName = _searchController.text.trim();
    final tripProvider = context.read<TripProvider>();

    // Get trips for this city
    final allTrips = tripProvider.nearbyTrips;
    final cityTrips = allTrips.where((trip) {
      if (trip is Trip) {
        return trip.city?.toLowerCase() == cityName.toLowerCase();
      } else if (trip is TripModel) {
        return trip.city?.toLowerCase() == cityName.toLowerCase();
      }
      return false;
    }).toList();

    // Close modal
    Navigator.of(context).pop();

    // Navigate to CityTripsScreen
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: GestureDetector(
          onTap: () {}, // Prevents tap from propagating to parent
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Content
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Close keyboard when tapping on free space
                        FocusScope.of(context).unfocus();
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1,
                                ),
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
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 17,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 22,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _searchController.clear();
                                            });
                                          },
                                          child: Icon(
                                            Icons.close,
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            size: 20,
                                          ),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _performSearch(),
                              ),
                            ),

                            // Suggestions dropdown
                            if (_showSuggestions || _isLoadingSuggestions) ...[
                              const SizedBox(height: 12),
                              _DarkContainer(
                                padding: EdgeInsets.zero,
                                child: _isLoadingSuggestions
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _filteredSuggestions.length,
                                        separatorBuilder: (context, index) =>
                                            Divider(
                                          color: Colors.white.withOpacity(0.1),
                                          height: 1,
                                          indent: 56,
                                        ),
                                        itemBuilder: (context, index) {
                                          final suggestion =
                                              _filteredSuggestions[index];
                                          return _SuggestionItem(
                                            city: suggestion,
                                            onTap: () =>
                                                _selectSuggestion(suggestion),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Spacing after search field when city is selected
                            if (!_showSuggestions &&
                                _searchController.text.trim().isNotEmpty)
                              const SizedBox(height: 12),

                            // Recent searches section (hidden when showing suggestions or when city is selected)
                            if (!_showSuggestions &&
                                _searchController.text.trim().isEmpty) ...[
                              const SizedBox(height: 12),
                              _DarkContainer(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recent',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
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
                              ),
                              const SizedBox(height: 12),
                            ],

                            // When section
                            _DarkContainer(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  // When section
                                  GestureDetector(
                                    onTap: () {
                                      // Close keyboard when opening When section
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        _isWhenExpanded = !_isWhenExpanded;
                                      });
                                    },
                                    child: _SearchSection(
                                      title: 'When',
                                      action: _selectedDateRange == null
                                          ? 'Add dates'
                                          : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                                    ),
                                  ),

                                  // When expanded content
                                  if (_isWhenExpanded)
                                    _WhenExpandedContent(
                                      selectedDateRange: _selectedDateRange,
                                      onDateRangeSelected: (range) {
                                        setState(() {
                                          _selectedDateRange = range;
                                          // Close after date selection
                                          _isWhenExpanded = false;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bottom search button
                            _DarkContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _selectedDateRange = null;
                                      });
                                      final tripProvider =
                                          context.read<TripProvider>();
                                      tripProvider.clearSearch();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Clear all',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 15,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: _performSearch,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      elevation: 4,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dark container widget with transparency
class _DarkContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _DarkContainer({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: child,
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
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start new selection
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        // Complete the range
        if (date.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
        // Notify parent
        widget.onDateRangeSelected(
          DateTimeRange(start: _startDate!, end: _endDate!),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
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
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar with limited height and scroll
          SizedBox(
            height: 380,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CalendarMonth(
                    month: 'November 2025',
                    year: 2025,
                    monthNumber: 11,
                    startDay: 20,
                    daysInMonth: 30,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 24),
                  _CalendarMonth(
                    month: 'December 2025',
                    year: 2025,
                    monthNumber: 12,
                    startDay: 1,
                    daysInMonth: 31,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 24),
                  _CalendarMonth(
                    month: 'January 2026',
                    year: 2026,
                    monthNumber: 1,
                    startDay: 1,
                    daysInMonth: 31,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 24),
                  _CalendarMonth(
                    month: 'February 2026',
                    year: 2026,
                    monthNumber: 2,
                    startDay: 1,
                    daysInMonth: 28,
                    onDateSelected: _onDateSelected,
                    startDate: _startDate,
                    endDate: _endDate,
                  ),
                  const SizedBox(height: 24),
                  _CalendarMonth(
                    month: 'March 2026',
                    year: 2026,
                    monthNumber: 3,
                    startDay: 1,
                    daysInMonth: 31,
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
  final int startDay;
  final int daysInMonth;
  final Function(DateTime) onDateSelected;
  final DateTime? startDate;
  final DateTime? endDate;

  const _CalendarMonth({
    required this.month,
    required this.year,
    required this.monthNumber,
    required this.startDay,
    required this.daysInMonth,
    required this.onDateSelected,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate first day of month (Monday = 1, Sunday = 7)
    final firstDayOfMonth = DateTime(year, monthNumber, 1);
    final weekdayOffset = firstDayOfMonth.weekday - 1; // Monday = 0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            month,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
            final isDisabled = month.contains('November') && day < 20;

            // Check if this date is selected
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
              onTap: isDisabled
                  ? null
                  : () {
                      onDateSelected(currentDate);
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: isDisabled
                      ? Colors.transparent
                      : (isStartDate || isEndDate)
                          ? AppColors.primary
                          : isInRange
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.white.withOpacity(0.2)
                          : (isStartDate || isEndDate)
                              ? Colors.white
                              : Colors.white,
                      fontSize: 15,
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
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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

class _SearchSection extends StatelessWidget {
  final String title;
  final String action;

  const _SearchSection({
    required this.title,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              Text(
                action,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Suggestion item widget
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: Colors.white.withOpacity(0.7),
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
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    city.country,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
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
