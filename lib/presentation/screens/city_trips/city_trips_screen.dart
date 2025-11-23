import 'dart:ui';
import 'dart:math' show sin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/models/trip.dart';
import '../../../core/models/trip_model.dart';
import '../home/widgets/trip_details_bottom_sheet.dart';
import '../home/widgets/activity_selector.dart';

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
  int _selectedActivity = -1;
  String? _selectedActivityType;
  double _scrollOpacity = 0.0;

  static const Map<int, String> _activityMap = {
    0: 'cycling',
    1: 'beach',
    2: 'skiing',
    3: 'mountains',
    4: 'hiking',
    5: 'sailing',
    6: 'desert',
    7: 'camping',
    8: 'city',
    9: 'wellness',
    10: 'road_trip',
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final newOpacity = (_scrollController.offset / 10.0).clamp(0.0, 1.0);
    if ((_scrollOpacity - newOpacity).abs() > 0.01) {
      setState(() => _scrollOpacity = newOpacity);
    }
  }

  void _onActivitySelected(int index) {
    setState(() {
      if (_selectedActivity == index) {
        _selectedActivity = -1;
        _selectedActivityType = null;
      } else {
        _selectedActivity = index;
        _selectedActivityType = _activityMap[index];
      }
    });
  }

  List<dynamic> _getFilteredTrips() {
    if (_selectedActivityType == null) return widget.trips;

    return widget.trips.where((trip) {
      if (trip is Trip) {
        return trip.activityType.toLowerCase() ==
            _selectedActivityType!.toLowerCase();
      } else if (trip is TripModel) {
        return trip.activityType?.toLowerCase() ==
            _selectedActivityType!.toLowerCase();
      }
      return false;
    }).toList();
  }

  String _getActivityName(String activityType) {
    final activityNames = {
      'cycling': 'Cycling',
      'beach': 'Beach',
      'skiing': 'Skiing',
      'mountains': 'Mountains',
      'hiking': 'Hiking',
      'sailing': 'Sailing',
      'desert': 'Desert',
      'camping': 'Camping',
      'city': 'City',
      'wellness': 'Wellness',
      'road_trip': 'Road Trip',
    };
    return activityNames[activityType.toLowerCase()] ?? activityType;
  }

  String _getHeaderTitle() {
    if (_selectedActivityType != null) {
      return '${_getActivityName(_selectedActivityType!)} in ${widget.cityName}';
    }
    return 'Trip in ${widget.cityName}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _getFilteredTrips();

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
            _AnimatedGradientHeader(opacity: 1 - _scrollOpacity),
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        ActivitySelector(
                          selectedIndex: _selectedActivity,
                          onActivitySelected: _onActivitySelected,
                          isDarkMode: true,
                        ),
                        const SizedBox(height: 8),
                        _SectionHeader(
                          title: _getHeaderTitle(),
                          isDarkMode: widget.isDarkMode,
                          onBackPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final trip = filteredTrips[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: _TripCard(
                            trip: trip,
                            isDarkMode: widget.isDarkMode,
                          ),
                        );
                      },
                      childCount: filteredTrips.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
            _SafeAreaBar(opacity: _scrollOpacity),
          ],
        ),
      ),
    );
  }
}

class _SafeAreaBar extends StatelessWidget {
  final double opacity;

  const _SafeAreaBar({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          color: AppColors.darkBackground.withOpacity(opacity),
        ),
      ),
    );
  }
}

class _AnimatedGradientHeader extends StatelessWidget {
  final double opacity;

  const _AnimatedGradientHeader({required this.opacity});

  static final _gradientColors = [
    const Color.fromARGB(255, 56, 22, 116).withOpacity(0.3),
    const Color.fromARGB(255, 51, 20, 103).withOpacity(0.3),
    const Color.fromARGB(255, 66, 27, 133).withOpacity(0.3),
    const Color.fromARGB(255, 78, 27, 161).withOpacity(0.25),
    const Color.fromARGB(255, 69, 23, 142).withOpacity(0.2),
    const Color.fromARGB(255, 56, 39, 2).withOpacity(0.15),
    const Color.fromARGB(255, 90, 40, 1).withOpacity(0.1),
    const Color(0xFF2E0052).withOpacity(0.07),
    const Color(0xFF1A0033).withOpacity(0.04),
    AppColors.darkBackground.withOpacity(0.02),
    AppColors.darkBackground.withOpacity(0.0),
  ];

  static const _gradientStops = [
    0.0,
    0.12,
    0.25,
    0.38,
    0.5,
    0.62,
    0.72,
    0.82,
    0.9,
    0.96,
    1.0
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        opacity: opacity,
        child: ClipPath(
          clipper: const _WavyBottomClipper(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _gradientColors,
                stops: _gradientStops,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDarkMode;
  final VoidCallback onBackPressed;

  const _SectionHeader({
    required this.title,
    required this.isDarkMode,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onBackPressed,
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_ios,
              color: Colors.white.withOpacity(0.9),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavyBottomClipper extends CustomClipper<Path> {
  const _WavyBottomClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height * 0.65);

    const waveCount = 4;
    const amplitude = 25.0;
    const pi = 3.14159;

    for (int i = 0; i <= 100; i++) {
      final x = width - (width / 100) * i;
      final normalizedX = i / 100.0;

      final wave1 = amplitude * 0.8 * sin(normalizedX * waveCount * pi);
      final wave2 = amplitude * 0.5 * sin(normalizedX * waveCount * 2 * pi);
      final wave3 = amplitude * 0.3 * sin(normalizedX * waveCount * 3 * pi);

      final y = height * 0.75 + wave1 + wave2 + wave3;
      path.lineTo(x, y);
    }

    path
      ..lineTo(0, height * 0.75)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TripCard extends StatefulWidget {
  final dynamic trip;
  final bool isDarkMode;

  const _TripCard({
    required this.trip,
    required this.isDarkMode,
  });

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _isFavorite = false;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTripTap() {
    Map<String, dynamic> tripData;

    if (widget.trip is Trip) {
      final trip = widget.trip as Trip;
      List<Map<String, dynamic>> itineraryData = [];
      if (trip.itinerary != null) {
        itineraryData = trip.itinerary!.map((day) => day.toJson()).toList();
      }

      tripData = {
        'id': trip.id,
        'title': trip.title,
        'description': trip.description,
        'duration': trip.duration,
        'price': trip.price,
        'rating': trip.rating,
        'reviews': trip.reviews,
        'images': trip.images?.map((img) => img.url).toList() ?? [],
        'includes': trip.includes ?? [],
        'highlights': trip.highlights ?? [],
        'itinerary': itineraryData,
        'image_url': trip.primaryImageUrl,
        'hero_image_url': trip.heroImageUrl ?? trip.primaryImageUrl,
        'city': trip.city,
        'country': trip.country,
        'latitude': trip.latitude,
        'longitude': trip.longitude,
      };
    } else if (widget.trip is TripModel) {
      final trip = widget.trip as TripModel;
      tripData = {
        'id': trip.id,
        'title': trip.title,
        'description': trip.description,
        'duration': trip.duration,
        'price': trip.price,
        'rating': trip.rating,
        'reviews': trip.reviews,
        'images': trip.images,
        'includes': trip.includes,
        'highlights': trip.highlights ?? [],
        'itinerary': trip.itinerary ?? [],
        'image_url': trip.imageUrl,
        'hero_image_url': trip.imageUrl,
        'city': trip.city,
        'country': trip.country,
        'latitude': trip.latitude,
        'longitude': trip.longitude,
      };
    } else {
      return;
    }

    TripDetailsBottomSheet.show(
      context,
      trip: tripData,
      isDarkMode: widget.isDarkMode,
    );
  }

  List<String> _getImages() {
    List<String> images = [];

    if (widget.trip is Trip) {
      final trip = widget.trip as Trip;

      // 1. Hero image first
      if (trip.heroImageUrl != null && trip.heroImageUrl!.isNotEmpty) {
        images.add(trip.heroImageUrl!);
      }

      // 2. Get images from trip.images array
      if (trip.images != null && trip.images!.isNotEmpty) {
        final tripImages = trip.images!.map((img) => img.url).toList();
        for (var url in tripImages) {
          if (!images.contains(url)) {
            images.add(url);
          }
        }
      }

      // 3. Extract from itinerary places if we need more images (up to 5)
      if (images.length < 5 && trip.itinerary != null) {
        for (var day in trip.itinerary!) {
          // Get from places (attractions, museums, etc)
          if (day.places != null) {
            for (var place in day.places!) {
              if (place.images != null && place.images!.isNotEmpty) {
                final imageUrl = place.images![0]['url']?.toString();
                if (imageUrl != null &&
                    imageUrl.isNotEmpty &&
                    !images.contains(imageUrl)) {
                  images.add(imageUrl);
                  if (images.length >= 5) break;
                }
              } else if (place.imageUrl != null &&
                  place.imageUrl!.isNotEmpty &&
                  !images.contains(place.imageUrl!)) {
                images.add(place.imageUrl!);
                if (images.length >= 5) break;
              }
            }
          }
          if (images.length >= 5) break;
        }
      }
    } else if (widget.trip is TripModel) {
      final tripModel = widget.trip as TripModel;
      images = tripModel.images ?? [];
    }

    return images;
  }

  @override
  Widget build(BuildContext context) {
    final images = _getImages();
    final title = widget.trip is Trip
        ? (widget.trip as Trip).title
        : (widget.trip as TripModel).title;
    final location = widget.trip is Trip
        ? '${(widget.trip as Trip).city}, ${(widget.trip as Trip).country}'
        : '${(widget.trip as TripModel).city}, ${(widget.trip as TripModel).country}';
    final duration = widget.trip is Trip
        ? (widget.trip as Trip).duration
        : (widget.trip as TripModel).duration;
    final price = widget.trip is Trip
        ? (widget.trip as Trip).price
        : (widget.trip as TripModel).price;
    final rating = widget.trip is Trip
        ? (widget.trip as Trip).rating
        : (widget.trip as TripModel).rating;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.isNotEmpty)
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: _onTripTap,
                            child: Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _onTripTap,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Gradient for visibility of indicators
                  if (images.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Telegram-style Bar Indicators
                  if (images.length > 1)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: List.generate(images.length, (index) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Trip info
          GestureDetector(
            onTap: _onTripTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color:
                              widget.isDarkMode ? Colors.white : AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating != null && rating > 0) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (duration != null && duration.isNotEmpty) ...[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.6)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        price ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              widget.isDarkMode ? Colors.white : AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
