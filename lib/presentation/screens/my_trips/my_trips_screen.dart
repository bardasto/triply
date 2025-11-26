import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/services/ai_trips_storage_service.dart';
import '../city_trips/models/activity_item.dart';
import '../city_trips/widgets/background/animated_gradient_header.dart';
import 'theme/my_trips_theme.dart';
import 'utils/trip_data_utils.dart';
import 'widgets/cards/compact_trip_card.dart';
import 'widgets/cards/trip_card.dart';
import 'widgets/filter/my_trips_filter_bottom_sheet.dart';
import 'widgets/header/my_trips_header.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
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
    await AiTripsStorageService.deleteTrip(tripId);
  }

  Future<void> _toggleFavorite(String tripId, bool currentValue) async {
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
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            AnimatedGradientHeader(
              opacity: (1 - (_scrollOffset / 100)).clamp(0.0, 1.0),
            ),
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: topPadding + MyTripsTheme.headerHeight + 16),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: MyTripsTheme.horizontalPadding),
                  sliver: _isGridView
                      ? _buildGridView(filteredTrips)
                      : _buildListView(filteredTrips),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<Map<String, dynamic>> trips) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MyTripsTheme.gridCrossAxisCount,
        crossAxisSpacing: MyTripsTheme.gridCrossAxisSpacing,
        mainAxisSpacing: MyTripsTheme.gridMainAxisSpacing,
        childAspectRatio: MyTripsTheme.gridAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final trip = trips[index];
          return CompactTripCard(
            trip: trip,
            onDelete: () => _deleteTrip(trip['id']),
            onToggleFavorite: () => _toggleFavorite(
              trip['id'],
              trip['is_favorite'] ?? false,
            ),
          );
        },
        childCount: trips.length,
      ),
    );
  }

  Widget _buildListView(List<Map<String, dynamic>> trips) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final trip = trips[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: MyTripsTheme.listCardSpacing),
            child: MyTripCard(
              trip: trip,
              onDelete: () => _deleteTrip(trip['id']),
              onToggleFavorite: () => _toggleFavorite(
                trip['id'],
                trip['is_favorite'] ?? false,
              ),
            ),
          );
        },
        childCount: trips.length,
      ),
    );
  }
}
