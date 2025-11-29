import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/services/ai_trips_storage_service.dart';
import '../city_trips/models/activity_item.dart';
import '../city_trips/widgets/background/animated_gradient_header.dart';
import '../home/widgets/trip_details/widgets/common/context_menu.dart';
import '../home/widgets/trip_details/widgets/common/context_menu_action.dart';
import 'theme/my_trips_theme.dart';
import 'utils/trip_data_utils.dart';
import 'widgets/cards/compact_trip_card.dart';
import 'widgets/cards/trip_card.dart';
import 'widgets/cards/trip_card_context_preview.dart';
import 'widgets/filter/my_trips_filter_bottom_sheet.dart';
import 'widgets/header/my_trips_header.dart' show MyTripsHeader, SearchSuggestion;

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  bool _isGridView = false;
  RealtimeChannel? _tripsChannel;

  // Scroll controller for header blur effect
  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;

  // Filter state
  final Set<int> _selectedActivities = {};
  final Set<String> _selectedActivityTypes = {};
  late RangeValues _priceRange;
  late double _minPrice;
  late double _maxPrice;
  List<double> _priceDistribution = [];

  // Search state
  String _searchQuery = '';
  bool _isSearchFocused = false;

  // Pull-to-search state
  bool _pullToSearchTriggered = false;
  static const double _pullToSearchThreshold = 150.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(keepScrollOffset: false)..addListener(_onScroll);
    _scrollOffset = 0.0; // Reset scroll offset
    _initPriceRange();
    _loadTrips();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cleanupRealtimeSubscription();
    super.dispose();
  }

  void _onScroll() {
    final newOffset = _scrollController.offset;
    if ((_scrollOffset - newOffset).abs() > 1) {
      setState(() => _scrollOffset = newOffset);
    }

    // Pull-to-search: detect negative offset (overscroll at top)
    if (!_isSearchFocused && newOffset < 0) {
      final pullAmount = -newOffset;

      // Open search immediately when threshold reached
      if (pullAmount >= _pullToSearchThreshold && !_pullToSearchTriggered) {
        _pullToSearchTriggered = true;
        HapticFeedback.mediumImpact();
        // Open search immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isSearchFocused = true;
            });
            _pullToSearchTriggered = false;
          }
        });
      }
    } else if (newOffset >= 0) {
      _pullToSearchTriggered = false;
    }
  }

  double get _pullToSearchProgress {
    if (_scrollOffset >= 0 || _isSearchFocused) return 0.0;
    return (-_scrollOffset / _pullToSearchThreshold).clamp(0.0, 1.5);
  }

  void _initPriceRange() {
    _minPrice = 0;
    _maxPrice = 2000;
    _priceRange = RangeValues(_minPrice, _maxPrice);
  }

  void _calculatePriceRange() {
    List<double> prices = [];
    for (var trip in _trips) {
      final price = MyTripDataUtils.parsePrice(trip['price']);
      if (price != null && price > 0) {
        prices.add(price);
      }
    }

    if (prices.isEmpty) {
      _minPrice = 0;
      _maxPrice = 2000;
      _priceRange = RangeValues(_minPrice, _maxPrice);
      _priceDistribution = [];
      return;
    }

    prices.sort();
    _minPrice = (prices.first / 50).floor() * 50.0;
    _maxPrice = ((prices.last / 50).ceil() * 50.0).clamp(_minPrice + 100, 5000);
    _priceRange = RangeValues(_minPrice, _maxPrice);

    // Calculate distribution for histogram
    const bucketCount = 50;
    final bucketSize = (_maxPrice - _minPrice) / bucketCount;
    _priceDistribution = List.filled(bucketCount, 0.0);

    for (var price in prices) {
      final bucketIndex =
          ((price - _minPrice) / bucketSize).floor().clamp(0, bucketCount - 1);
      _priceDistribution[bucketIndex]++;
    }
  }

  Future<void> _loadTrips() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final trips = await AiTripsStorageService.getAllTrips();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
    _calculatePriceRange();
  }

  void _setupRealtimeSubscription() {
    try {
      _tripsChannel = AiTripsStorageService.subscribeToTrips((trips) {
        if (mounted) {
          setState(() {
            _trips = trips;
          });
          _calculatePriceRange();
        }
      });
    } catch (e) {
      debugPrint('Error setting up realtime subscription: $e');
    }
  }

  Future<void> _cleanupRealtimeSubscription() async {
    if (_tripsChannel != null) {
      await AiTripsStorageService.unsubscribeFromTrips(_tripsChannel!);
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    // Optimistic update
    setState(() {
      _trips.removeWhere((trip) => trip['id'] == tripId);
    });
    _calculatePriceRange();
    await AiTripsStorageService.deleteTrip(tripId);
  }

  Future<void> _toggleFavorite(String tripId, bool currentValue) async {
    // Optimistic update
    setState(() {
      final index = _trips.indexWhere((trip) => trip['id'] == tripId);
      if (index != -1) {
        _trips[index] = {
          ..._trips[index],
          'is_favorite': !currentValue,
        };
      }
    });
    await AiTripsStorageService.toggleFavorite(tripId, !currentValue);
  }

  void _onActivitySelected(int index) {
    setState(() {
      if (_selectedActivities.contains(index)) {
        _selectedActivities.remove(index);
        _selectedActivityTypes.remove(ActivityItems.all[index].id);
      } else {
        _selectedActivities.add(index);
        _selectedActivityTypes.add(ActivityItems.all[index].id);
      }
    });
  }

  int _getTripCountForActivity(String activityId) {
    return _trips.where((trip) {
      final activityType = MyTripDataUtils.getActivityType(trip);
      return activityType?.toLowerCase() == activityId.toLowerCase();
    }).length;
  }

  List<Map<String, dynamic>> _getFilteredTrips() {
    return _trips.where((trip) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final title = MyTripDataUtils.getTitle(trip).toLowerCase();
        final location = MyTripDataUtils.getLocation(trip).toLowerCase();
        final city = (trip['city'] ?? '').toString().toLowerCase();
        final country = (trip['country'] ?? '').toString().toLowerCase();

        if (!title.contains(query) &&
            !location.contains(query) &&
            !city.contains(query) &&
            !country.contains(query)) {
          return false;
        }
      }

      // Activity filter
      if (_selectedActivityTypes.isNotEmpty) {
        final activityType = MyTripDataUtils.getActivityType(trip);
        if (activityType == null ||
            !_selectedActivityTypes.any((selected) =>
                selected.toLowerCase() == activityType.toLowerCase())) {
          return false;
        }
      }

      // Price filter
      final price = MyTripDataUtils.parsePrice(trip['price']);
      if (price != null) {
        if (price < _priceRange.start || price > _priceRange.end) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> _getSearchSuggestions() {
    if (_searchQuery.isEmpty) return [];

    final query = _searchQuery.toLowerCase();
    final suggestions = <String>{};

    for (final trip in _trips) {
      final city = trip['city']?.toString() ?? '';
      final country = trip['country']?.toString() ?? '';
      final title = MyTripDataUtils.getTitle(trip);

      if (city.isNotEmpty && city.toLowerCase().contains(query)) {
        suggestions.add(city);
      }
      if (country.isNotEmpty && country.toLowerCase().contains(query)) {
        suggestions.add(country);
      }
      if (title.toLowerCase().contains(query)) {
        suggestions.add(title);
      }

      if (suggestions.length >= 5) break;
    }

    return suggestions.take(5).toList();
  }

  List<String> _getUniqueCities() {
    final cities = <String>{};
    for (final trip in _trips) {
      final city = trip['city']?.toString() ?? '';
      if (city.isNotEmpty) {
        cities.add(city);
      }
    }
    return cities.toList()..sort();
  }

  List<String> _getUniqueCountries() {
    final countries = <String>{};
    for (final trip in _trips) {
      final country = trip['country']?.toString() ?? '';
      if (country.isNotEmpty) {
        countries.add(country);
      }
    }
    return countries.toList()..sort();
  }

  Set<String> _getUniqueActivityTypes() {
    final activityTypes = <String>{};
    for (final trip in _trips) {
      final activityType = MyTripDataUtils.getActivityType(trip);
      if (activityType != null && activityType.isNotEmpty) {
        activityTypes.add(activityType.toLowerCase());
      }
    }
    return activityTypes;
  }

  List<SearchSuggestion> _getSearchSuggestionsForHeader() {
    final suggestions = <SearchSuggestion>[];
    final query = _searchQuery.toLowerCase();
    final uniqueActivityTypes = _getUniqueActivityTypes();
    final addedLabels = <String>{};

    // Add matching trip titles first (when query is not empty)
    if (query.isNotEmpty) {
      for (final trip in _trips) {
        final title = MyTripDataUtils.getTitle(trip);
        if (title.toLowerCase().contains(query) && !addedLabels.contains(title)) {
          addedLabels.add(title);
          suggestions.add(SearchSuggestion(
            label: title,
            type: 'Trip',
            icon: PhosphorIconsBold.airplane,
            color: AppColors.primary,
          ));
        }
        if (suggestions.length >= 5) break;
      }
    }

    // Add cities
    for (final city in _getUniqueCities()) {
      if (suggestions.length >= 5) break;
      if (addedLabels.contains(city)) continue;
      if (query.isEmpty || city.toLowerCase().contains(query)) {
        addedLabels.add(city);
        suggestions.add(SearchSuggestion(
          label: city,
          type: 'City',
          icon: PhosphorIconsBold.mapPin,
          color: const Color(0xFF87CEEB),
        ));
      }
    }

    // Add countries
    for (final country in _getUniqueCountries()) {
      if (suggestions.length >= 5) break;
      if (addedLabels.contains(country)) continue;
      if (query.isEmpty || country.toLowerCase().contains(query)) {
        addedLabels.add(country);
        suggestions.add(SearchSuggestion(
          label: country,
          type: 'Country',
          icon: PhosphorIconsBold.globe,
          color: const Color(0xFF98D8C8),
        ));
      }
    }

    // Add activities that exist in user's trips
    for (final activity in ActivityItems.all) {
      if (suggestions.length >= 5) break;
      if (addedLabels.contains(activity.label)) continue;
      if (uniqueActivityTypes.contains(activity.id.toLowerCase())) {
        if (query.isEmpty || activity.label.toLowerCase().contains(query)) {
          addedLabels.add(activity.label);
          suggestions.add(SearchSuggestion(
            label: activity.label,
            type: 'Activity',
            icon: activity.icon,
            color: activity.color,
          ));
        }
      }
    }

    return suggestions.take(5).toList();
  }

  bool get _hasActiveFilters =>
      _selectedActivityTypes.isNotEmpty ||
      _priceRange.start > _minPrice ||
      _priceRange.end < _maxPrice ||
      _searchQuery.isNotEmpty;

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: MyTripsTheme.filterSheetHeightFactor,
          child: MyTripsFilterBottomSheet(
            activities: ActivityItems.all,
            selectedActivityIndices: _selectedActivities,
            getTripCount: _getTripCountForActivity,
            onActivitySelected: (index) {
              setModalState(() {});
              _onActivitySelected(index);
            },
            onClearFilter: () {
              setModalState(() {});
              setState(() {
                _selectedActivities.clear();
                _selectedActivityTypes.clear();
                _priceRange = RangeValues(_minPrice, _maxPrice);
                _searchQuery = '';
              });
            },
            priceRange: _priceRange,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            onPriceRangeChanged: (values) {
              setModalState(() {});
              setState(() => _priceRange = values);
            },
            priceDistribution: _priceDistribution,
            filteredCount: _getFilteredTrips().length,
            onShowResults: () => Navigator.pop(context),
            // Search
            searchQuery: _searchQuery,
            onSearchChanged: (value) {
              setState(() => _searchQuery = value);
              setModalState(() {});
            },
            searchSuggestions: _getSearchSuggestions(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_trips.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMainContent();
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppColors.darkBackground,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.darkBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.card_travel_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'No trips yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start planning with AI Chat!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final filteredTrips = _getFilteredTrips();
    final topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.darkBackground,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Gradient background
              AnimatedGradientHeader(
                opacity: _isSearchFocused ? 0.0 : (1 - (_scrollOffset / 100)).clamp(0.0, 1.0),
              ),
              // Content
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: _isSearchFocused ? 0.0 : MyTripsHeader.expandedSearchHeight,
                  end: _isSearchFocused ? MyTripsHeader.expandedSearchHeight : 0.0,
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Opacity(
                      opacity: _isSearchFocused ? 0.4 : 1.0,
                      child: child,
                    ),
                  );
                },
                child: IgnorePointer(
                  ignoring: _isSearchFocused,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                            height: topPadding + MyTripsTheme.headerWithSearchHeight + 16),
                      ),
                      _isGridView
                          ? _buildGridView(filteredTrips)
                          : _buildListView(filteredTrips),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    ],
                  ),
                ),
              ),
              MyTripsHeader(
                scrollOffset: _scrollOffset,
                tripsCount: filteredTrips.length,
                isGridView: _isGridView,
                hasActiveFilter: _hasActiveFilters,
                selectedActivities: _selectedActivities.isNotEmpty
                    ? _selectedActivities.map((i) => ActivityItems.all[i]).toList()
                    : null,
                onToggleView: (isGrid) {
                  HapticFeedback.lightImpact();
                  setState(() => _isGridView = isGrid);
                },
                onFilterPressed: _showFilterBottomSheet,
                searchQuery: _searchQuery,
                onSearchChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                suggestions: _getSearchSuggestionsForHeader(),
                onSearchFocusChanged: (isFocused) {
                  setState(() => _isSearchFocused = isFocused);
                },
                requestSearchFocus: _isSearchFocused,
                pullToSearchProgress: _pullToSearchProgress,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> trips) {
    final rowCount = (trips.length / 2).ceil();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, rowIndex) {
          final firstIndex = rowIndex * 2;
          final secondIndex = firstIndex + 1;
          final isLastRow = rowIndex == rowCount - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MyTripsTheme.horizontalPadding,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: MyTripsTheme.gridAspectRatio,
                          child: ContextMenu(
                            actions: [
                              ContextMenuAction(
                                label: 'Delete',
                                icon: CupertinoIcons.trash,
                                isDestructive: true,
                                onTap: () => _deleteTrip(trips[firstIndex]['id']),
                              ),
                            ],
                            preview: TripCardContextPreview(
                              child: CompactTripCard(
                                trip: trips[firstIndex],
                                onDelete: () {},
                                onToggleFavorite: () {},
                              ),
                            ),
                            child: CompactTripCard(
                              trip: trips[firstIndex],
                              onDelete: () => _deleteTrip(trips[firstIndex]['id']),
                              onToggleFavorite: () => _toggleFavorite(
                                trips[firstIndex]['id'],
                                trips[firstIndex]['is_favorite'] ?? false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: MyTripsTheme.gridCrossAxisSpacing),
                      Expanded(
                        child: secondIndex < trips.length
                            ? AspectRatio(
                                aspectRatio: MyTripsTheme.gridAspectRatio,
                                child: ContextMenu(
                                  actions: [
                                    ContextMenuAction(
                                      label: 'Delete',
                                      icon: CupertinoIcons.trash,
                                      isDestructive: true,
                                      onTap: () => _deleteTrip(trips[secondIndex]['id']),
                                    ),
                                  ],
                                  preview: TripCardContextPreview(
                                    child: CompactTripCard(
                                      trip: trips[secondIndex],
                                      onDelete: () {},
                                      onToggleFavorite: () {},
                                    ),
                                  ),
                                  child: CompactTripCard(
                                    trip: trips[secondIndex],
                                    onDelete: () => _deleteTrip(trips[secondIndex]['id']),
                                    onToggleFavorite: () => _toggleFavorite(
                                      trips[secondIndex]['id'],
                                      trips[secondIndex]['is_favorite'] ?? false,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLastRow) ...[
                const SizedBox(height: MyTripsTheme.gridMainAxisSpacing),
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.white24,
                ),
                const SizedBox(height: MyTripsTheme.gridMainAxisSpacing),
              ],
            ],
          );
        },
        childCount: rowCount,
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> trips) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final trip = trips[index];
          final isLast = index == trips.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: MyTripsTheme.horizontalPadding,
                  right: MyTripsTheme.horizontalPadding,
                  bottom: MyTripsTheme.listCardSpacing,
                ),
                child: ContextMenu(
                  actions: [
                    ContextMenuAction(
                      label: 'Delete',
                      icon: CupertinoIcons.trash,
                      isDestructive: true,
                      onTap: () => _deleteTrip(trip['id']),
                    ),
                  ],
                  preview: TripCardContextPreview(
                    child: MyTripCard(
                      trip: trip,
                      onDelete: () {},
                      onToggleFavorite: () {},
                    ),
                  ),
                  child: MyTripCard(
                    trip: trip,
                    onDelete: () => _deleteTrip(trip['id']),
                    onToggleFavorite: () => _toggleFavorite(
                      trip['id'],
                      trip['is_favorite'] ?? false,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.white24,
                ),
              if (!isLast) const SizedBox(height: MyTripsTheme.listCardSpacing),
            ],
          );
        },
        childCount: trips.length,
      ),
    );
  }
}
