import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/models/city_model.dart';
import '../../../../core/data/repositories/city_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../../../providers/trip_provider.dart';
import '../date_selection_dialog.dart';
import '../../../../core/models/country_model.dart';

class NearbyCountryCardsSection extends StatefulWidget {
  final String? userCountry;
  final bool isDarkMode;

  const NearbyCountryCardsSection({
    super.key,
    this.userCountry,
    required this.isDarkMode,
  });

  @override
  State<NearbyCountryCardsSection> createState() =>
      _NearbyCountryCardsSectionState();
}

class _NearbyCountryCardsSectionState extends State<NearbyCountryCardsSection> {
  // Constants
  static const int _gridColumns = 2;
  static const int _gridRows = 2;
  static const int _citiesPerPage = _gridColumns * _gridRows;
  static const int _maxPages = 2; // Only 2 pages max
  static const double _cardSpacing = 14.0;

  // State
  List<CityModel> _cities = [];
  bool _isLoading = true;
  final CityRepository _cityRepository = CityRepository();
  late PageController _pageController;
  int _currentPage = 0;
  Map<String, int> _cityTripsCount = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to TripProvider position changes
    final tripProvider = context.read<TripProvider>();
    if (tripProvider.userPosition != null && _cities.isNotEmpty) {
      _sortCitiesByPosition(tripProvider.userPosition!);
    }
    // Update trips count from real data
    _updateTripsCount(tripProvider);
  }

  void _updateTripsCount(TripProvider tripProvider) {
    // Use all available trips: publicTrips + nearbyPublicTrips
    final allTrips = <dynamic>[
      ...tripProvider.publicTrips,
      ...tripProvider.nearbyPublicTrips,
    ];

    // Remove duplicates by trip id
    final seenIds = <String>{};
    final uniqueTrips = allTrips.where((trip) {
      final id = trip.id as String;
      if (seenIds.contains(id)) return false;
      seenIds.add(id);
      return true;
    }).toList();

    final Map<String, int> counts = {};

    for (final trip in uniqueTrips) {
      final cityName = trip.city?.toLowerCase().trim() as String?;
      if (cityName != null && cityName.isNotEmpty) {
        counts[cityName] = (counts[cityName] ?? 0) + 1;
      }
    }

    debugPrint('🏙️ Trips count per city: $counts');

    if (mounted && counts.isNotEmpty && counts != _cityTripsCount) {
      setState(() {
        _cityTripsCount = counts;
      });
    }
  }

  int? _getTripsCountForCity(String cityName) {
    final count = _cityTripsCount[cityName.toLowerCase().trim()];
    return count != null && count > 0 ? count : null;
  }

  Map<String, int> get cityTripsCount => _cityTripsCount;

  Future<void> _loadCities() async {
    setState(() => _isLoading = true);

    try {
      // Load popular cities immediately (non-blocking)
      final popularCities = await _cityRepository.getPopularCities(limit: 20);

      if (mounted) {
        setState(() {
          _cities = popularCities;
          _isLoading = false;
        });

        // Check if TripProvider already has position
        final tripProvider = context.read<TripProvider>();
        if (tripProvider.userPosition != null) {
          _sortCitiesByPosition(tripProvider.userPosition!);
        }
      }
    } catch (e) {
      debugPrint('Error loading cities: $e');
      if (mounted) {
        setState(() {
          _cities = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sortCitiesByPosition(Position position) async {
    try {
      final sortedCities = await _cityRepository.getCitiesByDistance(
        userLat: position.latitude,
        userLon: position.longitude,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _cities = sortedCities;
        });
        debugPrint('📍 Cities sorted by distance');
      }
    } catch (e) {
      debugPrint('📍 Error sorting cities: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCityTap(CityModel city) {
    HapticFeedback.lightImpact();

    final countryModel = CountryModel(
      id: city.id,
      name: city.name,
      continent: city.country,
      imageUrl: city.imageUrl,
      rating: 4.5,
    );

    DateSelectionDialog.show(
      context,
      country: countryModel,
      isDarkMode: widget.isDarkMode,
      onDatesSelected: (startDate, endDate) {
        debugPrint('Selected ${city.name}: $startDate -> $endDate');
      },
    );
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = page);
  }

  int get _totalPages => (_cities.length / _citiesPerPage).ceil().clamp(0, _maxPages);

  @override
  Widget build(BuildContext context) {
    // Watch TripProvider to update trips count when trips change
    final tripProvider = context.watch<TripProvider>();

    // Update trips count whenever trips are available
    final hasTrips = tripProvider.publicTrips.isNotEmpty ||
                     tripProvider.nearbyPublicTrips.isNotEmpty;
    if (hasTrips) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateTripsCount(tripProvider);
        }
      });
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_cities.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          _buildPageView(),
          const SizedBox(height: 16), // Increased spacing
          _buildPageIndicator(),
        ],
      ),
    );
  }

  double _calculateGridHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 40; // padding 20 * 2
    final cardWidth = (availableWidth - _cardSpacing) / _gridColumns;
    final cardHeight = cardWidth; // square aspect ratio (1:1)
    return (cardHeight * _gridRows) + _cardSpacing + 4;
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 250,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city_rounded,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              'No cities available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageView() {
    final gridHeight = _calculateGridHeight(context);

    return SizedBox(
      height: gridHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const PageScrollPhysics(),
        itemCount: _totalPages,
        itemBuilder: (context, pageIndex) {
          return _buildPage(pageIndex);
        },
      ),
    );
  }

  Widget _buildPage(int pageIndex) {
    final startIndex = pageIndex * _citiesPerPage;
    final endIndex = (startIndex + _citiesPerPage).clamp(0, _cities.length);
    final pageCities = _cities.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridColumns,
          crossAxisSpacing: _cardSpacing,
          mainAxisSpacing: _cardSpacing,
          childAspectRatio: 1.0, // square cards
        ),
        itemCount: pageCities.length,
        itemBuilder: (context, index) {
          final city = pageCities[index];
          return _CityCard(
            city: city,
            tripsCount: _getTripsCountForCity(city.name),
            onTap: () => _onCityTap(city),
            isDarkMode: widget.isDarkMode,
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// City Card Widget - larger size
class _CityCard extends StatefulWidget {
  final CityModel city;
  final int? tripsCount;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _CityCard({
    required this.city,
    this.tripsCount,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  State<_CityCard> createState() => _CityCardState();
}

class _CityCardState extends State<_CityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.4 : 0.25),
                blurRadius: _isPressed ? 10 : 15,
                offset: Offset(0, _isPressed ? 3 : 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(),
                _buildGradient(),
                _buildInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return CachedNetworkImage(
      imageUrl: widget.city.imageUrl ?? 'https://via.placeholder.com/400',
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      memCacheWidth: 400,
      memCacheHeight: 400,
      placeholder: (context, url) => Container(
        color: const Color(0xFF2A2A2E),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFF2A2A2E),
        child: const Icon(
          Icons.location_city_rounded,
          color: Colors.white24,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.3, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.city.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.city.country,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.tripsCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.tripsCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Bottom Sheet with all cities
class AllCitiesBottomSheet extends StatefulWidget {
  final List<CityModel> cities;
  final bool isDarkMode;
  final Function(CityModel) onCityTap;
  final Position? userPosition;
  final Map<String, int> cityTripsCount;

  const AllCitiesBottomSheet({
    super.key,
    required this.cities,
    required this.isDarkMode,
    required this.onCityTap,
    this.userPosition,
    this.cityTripsCount = const {},
  });

  static void show(
    BuildContext context, {
    required List<CityModel> cities,
    required bool isDarkMode,
    required Function(CityModel) onCityTap,
    Position? userPosition,
    Map<String, int> cityTripsCount = const {},
  }) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AllCitiesBottomSheet(
        cities: cities,
        isDarkMode: isDarkMode,
        onCityTap: onCityTap,
        userPosition: userPosition,
        cityTripsCount: cityTripsCount,
      ),
    );
  }

  @override
  State<AllCitiesBottomSheet> createState() => _AllCitiesBottomSheetState();
}

class _AllCitiesBottomSheetState extends State<AllCitiesBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final CityRepository _cityRepository = CityRepository();
  List<CityModel> _allCities = [];
  List<CityModel> _filteredCities = [];
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _allCities = widget.cities;
    _filteredCities = widget.cities;
    _searchController.addListener(_onSearchChanged);

    // Try to sort by location in background
    _loadLocationSortedCities();
  }

  Future<void> _loadLocationSortedCities() async {
    Position? position = widget.userPosition;

    // If no position passed, try to get it
    position ??= await LocationService.getCurrentPosition();

    if (position != null && mounted) {
      final sortedCities = await _cityRepository.getCitiesByDistance(
        userLat: position.latitude,
        userLon: position.longitude,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _allCities = sortedCities;
          if (_searchController.text.isEmpty) {
            _filteredCities = sortedCities;
          }
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCities = _allCities;
      } else {
        _filteredCities = _allCities
            .where((city) =>
                city.name.toLowerCase().contains(query) ||
                city.country.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _onScroll(double offset) {
    if ((_scrollOffset - offset).abs() > 1) {
      setState(() => _scrollOffset = offset);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? const Color(0xFF1C1C1E)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              // City list below header
              Positioned.fill(
                child: Column(
                  children: [
                    const SizedBox(height: 90), // Space for header
                    Expanded(
                      child: _buildCityList(scrollController, bottomPadding),
                    ),
                  ],
                ),
              ),
              // Static header with blur effect
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildStaticHeader(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaticHeader() {
    final blurOpacity = ((_scrollOffset - 5) / 40).clamp(0.0, 1.0);
    final blur = 20.0 * blurOpacity;
    final bgColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.clamp,
        ),
        child: Container(
          color: bgColor.withValues(alpha: blurOpacity > 0 ? 0.7 : 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Search bar with close button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search cities...',
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.search_rounded,
                              color: widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Close button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Separator line
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 1,
                color: widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _getTripsCountForCity(String cityName) {
    final count = widget.cityTripsCount[cityName.toLowerCase().trim()];
    return count != null && count > 0 ? count : null;
  }

  Widget _buildCityList(ScrollController scrollController, double bottomPadding) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _onScroll(notification.metrics.pixels);
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: bottomPadding + 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _filteredCities.length,
        itemBuilder: (context, index) {
          final city = _filteredCities[index];
          return _CityListItem(
            city: city,
            tripsCount: _getTripsCountForCity(city.name),
            isDarkMode: widget.isDarkMode,
            onTap: () {
              Navigator.pop(context);
              widget.onCityTap(city);
            },
          );
        },
      ),
    );
  }
}

// City List Item for Bottom Sheet
class _CityListItem extends StatefulWidget {
  final CityModel city;
  final int? tripsCount;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _CityListItem({
    required this.city,
    this.tripsCount,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_CityListItem> createState() => _CityListItemState();
}

class _CityListItemState extends State<_CityListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withValues(alpha: _isPressed ? 0.12 : 0.08)
                : Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              // City image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: CachedNetworkImage(
                    imageUrl: widget.city.imageUrl ?? 'https://via.placeholder.com/100',
                    fit: BoxFit.cover,
                    fadeInDuration: Duration.zero,
                    placeholderFadeInDuration: Duration.zero,
                    memCacheWidth: 104,
                    memCacheHeight: 104,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFF2A2A2E),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFF2A2A2E),
                      child: const Icon(
                        Icons.location_city_rounded,
                        color: Colors.white24,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // City info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.city.name,
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.city.country,
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Trip count on the right
              if (widget.tripsCount != null)
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.tripsCount}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trips',
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: widget.isDarkMode
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
