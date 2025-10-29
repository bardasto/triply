import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/color_constants.dart';

class TripDetailsBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> trip,
    required bool isDarkMode,
  }) {
    // ✅ DEBUG: Проверяем что приходит
    print('🗺️ Trip data: ${trip.toString()}');
    print('📍 Latitude: ${trip['latitude']}');
    print('📍 Longitude: ${trip['longitude']}');
    print('🏙️ City: ${trip['city']}');
    print('🌍 Country: ${trip['country']}');

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TripDetailsContent(
        trip: trip,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class _TripDetailsContent extends StatefulWidget {
  final Map<String, dynamic> trip;
  final bool isDarkMode;

  const _TripDetailsContent({
    required this.trip,
    required this.isDarkMode,
  });

  @override
  State<_TripDetailsContent> createState() => _TripDetailsContentState();
}

class _TripDetailsContentState extends State<_TripDetailsContent>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  int _currentImageIndex = 0;
  GoogleMapController? _mapController;
  bool _isMapExpanded = false;
  bool _isMapPage = false;
  Set<Marker> _markers = {};

  bool get _isDark => widget.isDarkMode;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.text;
  Color get _textSecondary =>
      _isDark ? Colors.white70 : AppColors.textSecondary;
  Color get _dividerColor => _isDark ? Colors.white12 : Colors.grey[200]!;

  LatLng get _tripLocation {
    // ✅ ИСПРАВЛЕННАЯ ЛОГИКА ПОЛУЧЕНИЯ КООРДИНАТ
    try {
      double? lat;
      double? lng;

      // Пробуем разные варианты
      if (widget.trip['latitude'] != null) {
        if (widget.trip['latitude'] is double) {
          lat = widget.trip['latitude'];
        } else if (widget.trip['latitude'] is num) {
          lat = widget.trip['latitude'].toDouble();
        } else if (widget.trip['latitude'] is String) {
          lat = double.tryParse(widget.trip['latitude']);
        }
      }

      if (widget.trip['longitude'] != null) {
        if (widget.trip['longitude'] is double) {
          lng = widget.trip['longitude'];
        } else if (widget.trip['longitude'] is num) {
          lng = widget.trip['longitude'].toDouble();
        } else if (widget.trip['longitude'] is String) {
          lng = double.tryParse(widget.trip['longitude']);
        }
      }

      if (lat != null && lng != null) {
        print('✅ Using coordinates: $lat, $lng');
        return LatLng(lat, lng);
      }
    } catch (e) {
      print('❌ Error parsing coordinates: $e');
    }

    // Fallback на Париж
    print('⚠️ Using fallback coordinates (Paris)');
    return const LatLng(48.8566, 2.3522);
  }

  List<String> get _images {
    final tripImages = widget.trip['images'];

    if (tripImages != null && tripImages is List && tripImages.isNotEmpty) {
      return tripImages.cast<String>();
    }

    if (widget.trip['image_url'] != null) {
      return [widget.trip['image_url']];
    }

    return [
      'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800',
      'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800',
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
    ];
  }

  String get _formattedPrice {
    final price = widget.trip['price']?.toString() ?? '\$999';
    return price.replaceFirst('from ', '').replaceFirst('From ', '');
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _heightAnimation = Tween<double>(
      begin: 280.0,
      end: 500.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    _initializeMarker();
  }

  void _initializeMarker() {
    final location = _tripLocation;
    _markers = {
      Marker(
        markerId: const MarkerId('trip_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        ),
        infoWindow: InfoWindow(
          title: widget.trip['city'] ?? 'Location',
          snippet: widget.trip['country'] ?? '',
        ),
      ),
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _handleBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Booking functionality coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _toggleMapExpansion() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
      if (_isMapExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              _buildExpandableImageGallery(),
              Expanded(
                child: _buildScrollableContent(),
              ),
            ],
          ),
          _buildDragHandle(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildExpandableImageGallery() {
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return SizedBox(
          height:
              _isMapPage && _isMapExpanded ? _heightAnimation.value + 60 : 340,
          child: child,
        );
      },
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _isMapPage
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
                _isMapPage = (index == _images.length);
                if (!_isMapPage && _isMapExpanded) {
                  _isMapExpanded = false;
                  _animationController.reverse();
                }
              });
            },
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return _buildMapPage();
              }

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 280,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildImagePage(_images[index]),
                ),
              );
            },
          ),
          _buildPageIndicators(),
        ],
      ),
    );
  }

  Widget _buildImagePage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            cacheWidth: 800,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPage() {
    final location = _tripLocation;

    return Center(
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) {
          return SizedBox(
            height: _isMapExpanded ? _heightAnimation.value : 280,
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: Listener(
                    onPointerDown: (_) {
                      _pageController.position.hold(() {});
                    },
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: location, // ✅ ИСПОЛЬЗУЕМ АКТУАЛЬНУЮ ЛОКАЦИЮ
                        zoom: 14.0,
                      ),
                      mapType: MapType.normal,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      buildingsEnabled: true,
                      trafficEnabled: false,
                      indoorViewEnabled: false,
                      liteModeEnabled: false,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      gestureRecognizers: <Factory<
                          OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      },
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        controller.setMapStyle(null);
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggleMapExpansion,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isDark
                              ? Colors.black.withOpacity(0.7)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isMapExpanded
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            key: ValueKey(_isMapExpanded),
                            color: _isDark ? Colors.white : AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _images.length + 1,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentImageIndex == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentImageIndex == index
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Divider(height: 1, color: _dividerColor),
          _buildAboutSection(),
          Divider(height: 1, color: _dividerColor),
          if (widget.trip['includes'] != null &&
              (widget.trip['includes'] as List).isNotEmpty) ...[
            _buildIncludesSection(),
            Divider(height: 1, color: _dividerColor),
          ],
          _buildItinerarySection(),
          const SizedBox(height: 20),
          _buildBookButton(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.trip['title'] ?? 'Untitled Trip',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: _textSecondary),
              const SizedBox(width: 4),
              Text(
                widget.trip['duration'] ?? '7 days',
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${widget.trip['rating'] ?? 0.0}',
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'from '),
                TextSpan(
                  text: _formattedPrice,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this trip',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.trip['description'] ?? 'No description available.',
            style: TextStyle(
              fontSize: 16,
              color: _textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludesSection() {
    final includes = widget.trip['includes'] as List;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s included',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...includes.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.toString(),
                      style: TextStyle(fontSize: 16, color: _textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarySection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Itinerary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Explore amazing destinations and activities',
                          style: TextStyle(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: (_isDark ? Colors.white : Colors.grey).withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
