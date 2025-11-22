import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/color_constants.dart';
import '../../home/widgets/trip_details/trip_details_header.dart';
import '../../home/widgets/trip_details/trip_details_sections.dart';
import '../../home/widgets/trip_details/trip_details_utils.dart';
import '../../home/widgets/trip_details/trip_details_day_card.dart';

class AiGeneratedTripView extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onBack;

  const AiGeneratedTripView({
    super.key,
    required this.trip,
    required this.onBack,
  });

  @override
  State<AiGeneratedTripView> createState() => _AiGeneratedTripViewState();
}

class _AiGeneratedTripViewState extends State<AiGeneratedTripView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  final Map<int, bool> _expandedDays = {};
  final Set<String> _selectedPlaceIds = {};

  double _scrollOpacity = 0.0;
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Calculate opacity for header background based on scroll
    final offset = _scrollController.offset;
    final newOpacity = (offset / 200).clamp(0.0, 1.0);
    final newHeaderOpacity = (offset / 100).clamp(0.0, 1.0);

    if ((_scrollOpacity - newOpacity).abs() > 0.01) {
      setState(() {
        _scrollOpacity = newOpacity;
        _headerOpacity = newHeaderOpacity;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _heroImage {
    final heroImageUrl = widget.trip['hero_image_url'] as String?;
    if (heroImageUrl != null && heroImageUrl.isNotEmpty) {
      return heroImageUrl;
    }

    final images = TripDetailsUtils.extractImagesFromTrip(widget.trip);
    if (images.isNotEmpty) {
      return images.first;
    }

    return 'https://via.placeholder.com/800x600?text=Trip+Image';
  }

  String get _tripTitle {
    return widget.trip['name'] as String? ?? 'Trip to ${widget.trip['city'] ?? 'Unknown'}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          children: [
            // Main scrollable content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Hero Image
                SliverToBoxAdapter(
                  child: _buildHeroImage(),
                ),

                // Trip content
                SliverToBoxAdapter(
                  child: _buildTripContent(),
                ),
              ],
            ),

            // Floating header with back button
            _buildFloatingHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Stack(
      children: [
        // Image
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(_heroImage),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  AppColors.darkBackground.withValues(alpha: 0.8),
                  AppColors.darkBackground,
                ],
                stops: const [0.0, 0.3, 0.85, 1.0],
              ),
            ),
          ),
        ),

        // Trip title at bottom of image
        Positioned(
          left: 20,
          right: 20,
          bottom: 30,
          child: Text(
            _tripTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 8,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.darkBackground.withValues(alpha: _scrollOpacity),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3 + (_scrollOpacity * 0.4)),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (_headerOpacity > 0.5) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Opacity(
                      opacity: _headerOpacity,
                      child: Text(
                        _tripTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripContent() {
    final dividerColor = Colors.white.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header (duration, price, etc.)
        TripDetailsHeader(trip: widget.trip, isDark: true),

        Divider(height: 1, color: dividerColor),

        // About section
        TripDetailsSections.buildAboutSection(
          trip: widget.trip,
          isDark: true,
        ),

        Divider(height: 1, color: dividerColor),

        // Includes section (if exists)
        if (widget.trip['includes'] != null &&
            (widget.trip['includes'] as List).isNotEmpty) ...[
          TripDetailsSections.buildIncludesSection(
            trip: widget.trip,
            isDark: true,
          ),
          Divider(height: 1, color: dividerColor),
        ],

        // Itinerary section
        _buildItinerarySection(),

        const SizedBox(height: 20),

        // Book button
        TripDetailsSections.buildBookButton(
          onBook: _handleBooking,
          isDark: true,
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildItinerarySection() {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null || itinerary.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Itinerary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detailed itinerary coming soon',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Places'),
                Tab(text: 'Restaurants'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_tabController.index == 0)
            _buildPlacesTab(itinerary)
          else
            _buildRestaurantsTab(itinerary),
        ],
      ),
    );
  }

  Widget _buildPlacesTab(List<dynamic> itinerary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: itinerary.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value as Map<String, dynamic>;

        final allPlaces = day['places'] as List?;
        if (allPlaces != null) {
          final filteredPlaces = allPlaces.where((place) {
            final category = place['category'] as String?;
            return category != 'breakfast' &&
                category != 'lunch' &&
                category != 'dinner';
          }).toList();

          if (filteredPlaces.isEmpty) {
            return const SizedBox.shrink();
          }

          final filteredDay = Map<String, dynamic>.from(day);
          filteredDay['places'] = filteredPlaces;
          return _buildDayCard(filteredDay, index);
        }

        return _buildDayCard(day, index);
      }).toList(),
    );
  }

  Widget _buildRestaurantsTab(List<dynamic> itinerary) {
    final List<Map<String, dynamic>> restaurants = [];

    for (var day in itinerary) {
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        for (var restaurant in dayRestaurants) {
          restaurants.add(restaurant as Map<String, dynamic>);
        }
      }

      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category == 'breakfast' ||
              category == 'lunch' ||
              category == 'dinner') {
            restaurants.add(place as Map<String, dynamic>);
          }
        }
      }
    }

    if (restaurants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Colors.white70),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No restaurants added yet',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: restaurants.map((restaurant) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.restaurant, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  restaurant['name'] ?? 'Restaurant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final dayNumber = day['day'] ?? (index + 1);
    final isExpanded = _expandedDays[dayNumber] ?? false;

    return TripDetailsDayCard(
      day: day,
      index: index,
      isExpanded: isExpanded,
      isDark: true,
      trip: widget.trip,
      selectedPlaceIds: _selectedPlaceIds,
      onToggleExpand: () {
        setState(() {
          _expandedDays[dayNumber] = !isExpanded;
        });
      },
      onAddPlace: () {
        // Disabled in AI chat view
      },
      onEditPlace: (place) {
        // Disabled in AI chat view
      },
      onDeletePlace: (place) {
        // Disabled in AI chat view
      },
      onToggleSelection: (placeId) {
        // Disabled in AI chat view
      },
      onPlaceLongPress: (place) {
        // Disabled in AI chat view
      },
    );
  }

  void _handleBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Booking functionality coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
