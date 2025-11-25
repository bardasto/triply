import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/color_constants.dart';
import 'models/activity_item.dart';
import 'theme/city_trips_theme.dart';
import 'utils/trip_data_utils.dart';
import 'widgets/background/animated_gradient_header.dart';
import 'widgets/cards/compact_trip_card.dart';
import 'widgets/cards/trip_card.dart';
import 'widgets/filter/filter_bottom_sheet.dart';
import 'widgets/header/city_trips_header.dart';

class CityTripsScreen extends StatefulWidget {
  final String cityName;
  final List<dynamic> trips;
  final bool isDarkMode;

  const CityTripsScreen({
    super.key,
    required this.cityName,
    required this.trips,
    required this.isDarkMode,
  });

  @override
  State<CityTripsScreen> createState() => _CityTripsScreenState();
}

class _CityTripsScreenState extends State<CityTripsScreen> {
  late final ScrollController _scrollController;
  final Set<int> _selectedActivities = {};
  final Set<String> _selectedActivityTypes = {};
  double _scrollOffset = 0.0;
  bool _isGridView = false;

  // Price filter
  late RangeValues _priceRange;
  late double _minPrice;
  late double _maxPrice;
  List<double> _priceDistribution = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _calculatePriceRange();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _calculatePriceRange() {
    List<double> prices = [];
    for (var trip in widget.trips) {
      final price = TripDataUtils.parsePrice(TripDataUtils.getPrice(trip));
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

  void _onScroll() {
    final newOffset = _scrollController.offset;
    if ((_scrollOffset - newOffset).abs() > 1) {
      setState(() => _scrollOffset = newOffset);
    }
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
    return widget.trips.where((trip) {
      final activityType = TripDataUtils.getActivityType(trip);
      return activityType?.toLowerCase() == activityId.toLowerCase();
    }).length;
  }

  void _showFilterBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: CityTripsTheme.filterSheetHeightFactor,
          child: FilterBottomSheet(
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
          ),
        ),
      ),
    );
  }

  List<dynamic> _getFilteredTrips() {
    return widget.trips.where((trip) {
      // Activity filter
      if (_selectedActivityTypes.isNotEmpty) {
        final activityType = TripDataUtils.getActivityType(trip);
        if (activityType == null ||
            !_selectedActivityTypes.any((selected) =>
                selected.toLowerCase() == activityType.toLowerCase())) {
          return false;
        }
      }

      // Price filter
      final price = TripDataUtils.parsePrice(TripDataUtils.getPrice(trip));
      if (price != null) {
        if (price < _priceRange.start || price > _priceRange.end) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedActivityTypes.isNotEmpty ||
      _priceRange.start > _minPrice ||
      _priceRange.end < _maxPrice;

  String _getHeaderTitle() {
    if (_selectedActivityTypes.length == 1) {
      return '${ActivityItems.getName(_selectedActivityTypes.first)} in ${widget.cityName}';
    } else if (_selectedActivityTypes.length > 1) {
      return '${_selectedActivityTypes.length} activities in ${widget.cityName}';
    }
    return 'Trips in ${widget.cityName}';
  }

  @override
  Widget build(BuildContext context) {
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
                      height: topPadding + CityTripsTheme.headerHeight + 16),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: CityTripsTheme.horizontalPadding),
                  sliver: _isGridView
                      ? _buildGridView(filteredTrips)
                      : _buildListView(filteredTrips),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
            CityTripsHeader(
              scrollOffset: _scrollOffset,
              title: _getHeaderTitle(),
              isGridView: _isGridView,
              hasActiveFilter: _hasActiveFilters,
              selectedActivities: _selectedActivities.isNotEmpty
                  ? _selectedActivities.map((i) => ActivityItems.all[i]).toList()
                  : null,
              onBackPressed: () => Navigator.pop(context),
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

  Widget _buildGridView(List<dynamic> trips) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: CityTripsTheme.gridCrossAxisCount,
        crossAxisSpacing: CityTripsTheme.gridCrossAxisSpacing,
        mainAxisSpacing: CityTripsTheme.gridMainAxisSpacing,
        childAspectRatio: CityTripsTheme.gridAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => CompactTripCard(
          trip: trips[index],
          isDarkMode: widget.isDarkMode,
        ),
        childCount: trips.length,
      ),
    );
  }

  Widget _buildListView(List<dynamic> trips) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: CityTripsTheme.listCardSpacing),
          child: TripCard(
            trip: trips[index],
            isDarkMode: widget.isDarkMode,
          ),
        ),
        childCount: trips.length,
      ),
    );
  }
}
