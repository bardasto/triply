import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/data/repositories/city_repository.dart';
import '../../../../../core/models/city_model.dart';
import '../../../../../core/models/trip.dart';
import '../../../../../core/models/trip_model.dart';
import '../../../../../providers/trip_provider.dart';
import '../../../city_trips/city_trips_screen.dart';
import 'theme/search_theme.dart';
import 'widgets/header/search_drag_handle.dart';
import 'widgets/header/search_close_button.dart';
import 'widgets/content/search_text_field.dart';
import 'widgets/content/suggestions_container.dart';
import 'widgets/content/recent_searches_section.dart';
import 'widgets/content/when_section.dart';
import 'widgets/content/search_bottom_buttons.dart';

/// Search modal bottom sheet for finding destinations.
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
  bool _isExpanded = false;
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
    if (_focusNode.hasFocus) {
      setState(() {
        _isExpanded = true;
        _isWhenExpanded = false;
      });
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

  void _onWhenToggle() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isWhenExpanded = !_isWhenExpanded;
      if (_isWhenExpanded) {
        _isExpanded = true;
        _showSuggestions = false;
        _filteredSuggestions = [];
        _isLoadingSuggestions = false;
      }
    });
  }

  void _onClearSearch() {
    setState(() {
      _searchController.clear();
      _showSuggestions = false;
      _filteredSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final compactHeight = SearchTheme.compactHeight + bottomPadding;
    final expandedHeight = screenHeight * SearchTheme.expandedHeightFactor;
    final sheetHeight = _isExpanded || keyboardHeight > 0 ? expandedHeight : compactHeight;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(SearchTheme.sheetRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: sheetHeight,
          decoration: SearchTheme.sheetDecoration,
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: SearchTheme.headerSpacing),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          left: SearchTheme.contentPadding,
                          right: SearchTheme.contentPadding,
                          bottom: keyboardHeight + bottomPadding + SearchTheme.contentPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SearchTextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              onClear: _onClearSearch,
                              onSubmitted: (_) => _performSearch(),
                            ),

                            if (_showSuggestions || _isLoadingSuggestions) ...[
                              const SizedBox(height: SearchTheme.elementSpacing),
                              SuggestionsContainer(
                                isLoading: _isLoadingSuggestions,
                                suggestions: _filteredSuggestions,
                                onSuggestionSelected: _selectSuggestion,
                              ),
                            ],

                            if (!_showSuggestions && !_isLoadingSuggestions &&
                                _searchController.text.trim().isNotEmpty)
                              const SizedBox(height: SearchTheme.elementSpacing),

                            if (!_showSuggestions && !_isLoadingSuggestions &&
                                _searchController.text.trim().isEmpty) ...[
                              const SizedBox(height: SearchTheme.elementSpacing),
                              RecentSearchesSection(
                                onRecentItemTap: () {
                                  _searchController.text = 'Barcelona';
                                  _performSearch();
                                },
                              ),
                            ],

                            const SizedBox(height: SearchTheme.elementSpacing),

                            WhenSection(
                              isExpanded: _isWhenExpanded,
                              selectedDateRange: _selectedDateRange,
                              onToggle: _onWhenToggle,
                              onDateRangeSelected: (range) {
                                setState(() {
                                  _selectedDateRange = range;
                                  _isWhenExpanded = false;
                                });
                              },
                            ),

                            const SizedBox(height: SearchTheme.elementSpacing),

                            SearchBottomButtons(
                              onClearAll: _clearAll,
                              onSearch: _performSearch,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SearchDragHandle(),
              SearchCloseButton(onClose: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
