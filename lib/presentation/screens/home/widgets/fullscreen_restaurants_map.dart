import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/color_constants.dart';

/// Fullscreen map view showing all restaurants from a trip
class FullscreenRestaurantsMap extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final bool isDark;
  final String? tripCity;
  final String? editingRestaurantId; // ID of restaurant being edited
  final Function(Map<String, dynamic>)? onRestaurantSelected; // Callback when restaurant selected

  const FullscreenRestaurantsMap({
    super.key,
    required this.restaurants,
    required this.isDark,
    this.tripCity,
    this.editingRestaurantId,
    this.onRestaurantSelected,
  });

  @override
  State<FullscreenRestaurantsMap> createState() =>
      _FullscreenRestaurantsMapState();
}

class _FullscreenRestaurantsMapState extends State<FullscreenRestaurantsMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedRestaurant;
  int? _selectedRestaurantIndex;
  int _selectedPhotoIndex = 0;
  int _selectedTabIndex = 0; // For Overview, Menu, Reviews, etc.
  bool _isDescriptionExpanded = false; // For "See more" functionality
  bool _isOpeningHoursExpanded = false; // For opening hours expand/collapse
  final PageController _photoPageController = PageController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Filter and sort states
  String? _priceSortOrder; // null, 'asc' (cheap to expensive), 'desc' (expensive to cheap)
  bool _topRatedFilter = false;
  bool _openNowFilter = false;
  String? _selectedCuisine;

  // Dark map style JSON
  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#212121"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#181818"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#2c2c2c"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8a8a8a"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [{"color": "#373737"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{"color": "#3c3c3c"}]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [{"color": "#4e4e4e"}]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#3d3d3d"}]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    _photoPageController.dispose();
    super.dispose();
  }

  /// ✅ Метка с иконкой слева и рейтингом справа (как на скрине)
  Future<BitmapDescriptor> _createMarkerWithRating({
    required double? rating,
    required bool isSelected,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Размеры
    const double height = 24;
    const double iconSize = 25;
    const double padding = 6;

    // Определяем ширину в зависимости от наличия рейтинга
    final double width = rating != null && rating > 0
        ? iconSize + padding * 2 + 32 // иконка + отступ + текст рейтинга
        : iconSize + padding * 2; // только иконка

    // Цвета
    final Color bgColor = isSelected
        ? AppColors.primary
        : const Color(0xFFEA4335); // Красный как в Google Maps

    // ✅ Рисуем тень
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final shadowPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, width, height),
          const Radius.circular(18),
        ),
      );
    canvas.drawPath(shadowPath, shadowPaint);

    // ✅ Рисуем фон метки (скругленный прямоугольник)
    final bgPaint = Paint()..color = bgColor;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(18),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // ✅ Рисуем иконку ресторана слева
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.restaurant.codePoint),
        style: TextStyle(
          fontSize: 18,
          fontFamily: Icons.restaurant.fontFamily,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        padding + (iconSize - 18) / 2,
        (height - iconPainter.height) / 2,
      ),
    );

    // ✅ Рисуем рейтинг справа (без звездочки)
    if (rating != null && rating > 0) {
      final ratingPainter = TextPainter(
        text: TextSpan(
          text: rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      ratingPainter.layout();
      ratingPainter.paint(
        canvas,
        Offset(
          iconSize + padding + 4,
          (height - ratingPainter.height) / 2,
        ),
      );
    }

    // ✅ Рисуем стрелку вниз
    final trianglePath = Path();
    trianglePath.moveTo(width / 2 - 6, height);
    trianglePath.lineTo(width / 2, height + 10);
    trianglePath.lineTo(width / 2 + 6, height);
    trianglePath.close();
    canvas.drawPath(trianglePath, bgPaint);

    final img = await pictureRecorder.endRecording().toImage(
          width.toInt(),
          (height + 10).toInt(),
        );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  void _createMarkers() async {
    final markers = <Marker>{};

    for (int i = 0; i < widget.restaurants.length; i++) {
      final restaurant = widget.restaurants[i];
      final lat = (restaurant['latitude'] as num?)?.toDouble();
      final lng = (restaurant['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      final isSelected = _selectedRestaurant != null &&
          (restaurant['poi_id']?.toString() ?? restaurant['name']) ==
              (_selectedRestaurant!['poi_id']?.toString() ??
                  _selectedRestaurant!['name']);

      final double? rating = (restaurant['rating'] as num?)?.toDouble();

      final customIcon = await _createMarkerWithRating(
        rating: rating,
        isSelected: isSelected,
      );

      markers.add(
        Marker(
          markerId: MarkerId('restaurant_$i'),
          position: LatLng(lat, lng),
          icon: customIcon,
          anchor: const Offset(0.5, 1.0),
          onTap: () => _onMarkerTapped(restaurant, i),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTapped(Map<String, dynamic> restaurant, int index) {
    // Always show restaurant details when clicked
    setState(() {
      _selectedRestaurant = restaurant;
      _selectedRestaurantIndex = index;
      _selectedPhotoIndex = 0;
      _selectedTabIndex = 0;
      _isDescriptionExpanded = false; // Reset description state
      _isOpeningHoursExpanded = false; // Reset opening hours state
    });
    _createMarkers();

    // Reset photo page controller
    if (_photoPageController.hasClients) {
      _photoPageController.jumpToPage(0);
    }

    // Expand bottom sheet to 90% to show selected restaurant details
    _sheetController.animateTo(
      0.9,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    // Center map on selected restaurant
    final lat = (restaurant['latitude'] as num?)?.toDouble();
    final lng = (restaurant['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
      );
    }
  }

  void _fitMapToMarkers() {
    if (widget.restaurants.isEmpty || _mapController == null) return;

    double? minLat, maxLat, minLng, maxLng;

    for (var restaurant in widget.restaurants) {
      final lat = (restaurant['latitude'] as num?)?.toDouble();
      final lng = (restaurant['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
      maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
      minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
      maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    }
  }

  LatLng get _initialPosition {
    if (widget.restaurants.isEmpty) {
      return const LatLng(48.8566, 2.3522);
    }

    final first = widget.restaurants[0];
    final lat = (first['latitude'] as num?)?.toDouble() ?? 48.8566;
    final lng = (first['longitude'] as num?)?.toDouble() ?? 2.3522;
    return LatLng(lat, lng);
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return 'Restaurant';
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.amber;
      case 'dinner':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.restaurant;
    }
  }

  /// Format opening hours from Map or String to display string
  String _formatOpeningHours(dynamic openingHours) {
    if (openingHours == null) return '';

    // If it's already a string, return it
    if (openingHours is String) {
      return openingHours;
    }

    // If it's a Map, try to extract useful information
    if (openingHours is Map<String, dynamic>) {
      // Try to get today's hours or a general summary
      if (openingHours.containsKey('weekday_text')) {
        final weekdayText = openingHours['weekday_text'];
        if (weekdayText is List && weekdayText.isNotEmpty) {
          // Get first day's hours as summary
          return weekdayText.first.toString();
        }
      }

      // Fallback: indicate that hours are available
      return 'Hours available';
    }

    return '';
  }

  /// Format price level to euros string (e.g., 2 -> "€€")
  String? _formatPriceLevel(dynamic priceLevel) {
    if (priceLevel == null) return null;

    int level = 0;
    if (priceLevel is int) {
      level = priceLevel;
    } else if (priceLevel is String) {
      level = int.tryParse(priceLevel) ?? 0;
    } else if (priceLevel is double) {
      level = priceLevel.round();
    }

    if (level <= 0 || level > 4) return null;

    return '€' * level;
  }

  /// Format cuisine types array to display string (e.g., ["Italian", "Pizza"] -> "Italian, Pizza")
  String? _formatCuisineTypes(dynamic cuisineTypes) {
    if (cuisineTypes == null) return null;

    if (cuisineTypes is List && cuisineTypes.isNotEmpty) {
      final types = cuisineTypes
          .where((type) => type != null && type.toString().isNotEmpty)
          .map((type) => type.toString())
          .toList();

      if (types.isEmpty) return null;

      return types.join(', ');
    } else if (cuisineTypes is String && cuisineTypes.isNotEmpty) {
      return cuisineTypes;
    }

    return null;
  }

  /// Get opening status text (e.g., "Open", "Closed", or time string)
  String _getOpeningStatus(dynamic openingHours) {
    print('═══════════════════════════════════════');
    print('🕐 DEBUG: Opening Hours Status (fullscreen_restaurants_map)');
    print('openingHours type: ${openingHours.runtimeType}');
    print('openingHours value: $openingHours');

    if (openingHours == null) {
      print('❌ openingHours is null');
      print('═══════════════════════════════════════\n');
      return 'Hours not available';
    }

    // ✅ Handle String format (e.g., "9:00 - 18:00")
    if (openingHours is String) {
      print('✅ openingHours is String: $openingHours');
      print('═══════════════════════════════════════\n');
      if (openingHours.trim().isEmpty) {
        return 'Hours not available';
      }
      // Return the hours string as-is
      return openingHours;
    }

    // ✅ Handle Map format (Google Places API format)
    if (openingHours is Map<String, dynamic>) {
      final openNow = openingHours['open_now'] as bool?;
      final weekdayText = openingHours['weekday_text'] as List?;

      print('open_now: $openNow');
      print('weekday_text: $weekdayText');

      if (weekdayText == null || weekdayText.isEmpty) {
        print('❌ weekday_text is null or empty');
        print('═══════════════════════════════════════\n');
        return 'Hours not available';
      }

      // Get current day (0 = Sunday, 1 = Monday, etc.)
      final now = DateTime.now();
      final currentDay = now.weekday % 7;

      // Get today's hours from weekday_text
      String todayHours = '';
      if (weekdayText.length > currentDay) {
        todayHours = weekdayText[currentDay].toString();
        if (todayHours.contains(':')) {
          todayHours = todayHours.split(':').skip(1).join(':').trim();
        }
      }

      if (todayHours.toLowerCase().contains('closed')) {
        return 'Closed';
      }

      if (openNow == true) {
        return 'Open';
      } else {
        return 'Closed';
      }
    }

    print('❌ openingHours is neither String nor Map');
    print('═══════════════════════════════════════\n');
    return 'Hours not available';
  }

  /// Get list of weekday hours
  List<String> _getWeekdayHours(dynamic openingHours) {
    if (openingHours == null) {
      return [];
    }

    // ✅ If it's a String, we don't have detailed weekday hours
    if (openingHours is String) {
      return [];
    }

    // ✅ If it's a Map, try to get weekday_text
    if (openingHours is Map<String, dynamic>) {
      final weekdayText = openingHours['weekday_text'] as List?;
      if (weekdayText == null || weekdayText.isEmpty) {
        return [];
      }
      return weekdayText.map((e) => e.toString()).toList();
    }

    return [];
  }

  /// Open website in browser
  Future<void> _openWebsite(String? website) async {
    if (website == null || website.isEmpty) return;

    final url = Uri.parse(website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open website')),
      );
    }
  }

  /// Open directions to restaurant
  Future<void> _openDirections(double lat, double lng) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  /// Get available cuisine types from restaurants
  List<String> _getAvailableCuisines() {
    final Set<String> cuisines = {};
    for (var restaurant in widget.restaurants) {
      final cuisine = restaurant['cuisine'] as String?;
      if (cuisine != null && cuisine.isNotEmpty) {
        cuisines.add(cuisine);
      }
    }
    return cuisines.toList()..sort();
  }

  /// Get filtered and sorted restaurants
  List<Map<String, dynamic>> _getFilteredRestaurants() {
    List<Map<String, dynamic>> filtered = List.from(widget.restaurants);

    // Filter by open now
    if (_openNowFilter) {
      filtered = filtered.where((r) {
        return _isRestaurantOpen(r['opening_hours']);
      }).toList();
    }

    // Filter by cuisine
    if (_selectedCuisine != null) {
      filtered = filtered.where((r) {
        final cuisine = r['cuisine'] as String?;
        return cuisine == _selectedCuisine;
      }).toList();
    }

    // Sort by price
    if (_priceSortOrder != null) {
      filtered.sort((a, b) {
        final priceA = _getPriceLevel(a['price_level']);
        final priceB = _getPriceLevel(b['price_level']);

        if (_priceSortOrder == 'asc') {
          return priceA.compareTo(priceB);
        } else {
          return priceB.compareTo(priceA);
        }
      });
    }

    // Sort by rating
    if (_topRatedFilter) {
      filtered.sort((a, b) {
        final ratingA = (a['rating'] as num?)?.toDouble() ?? 0.0;
        final ratingB = (b['rating'] as num?)?.toDouble() ?? 0.0;
        return ratingB.compareTo(ratingA); // Highest first
      });
    }

    return filtered;
  }

  /// Check if restaurant is currently open
  bool _isRestaurantOpen(dynamic openingHours) {
    if (openingHours == null) return false;

    // Handle Map format (Google Places API format)
    if (openingHours is Map<String, dynamic>) {
      final openNow = openingHours['open_now'] as bool?;
      return openNow ?? false;
    }

    // Handle String format - check if it contains "Open"
    if (openingHours is String) {
      final status = _getOpeningStatus(openingHours);
      return status.toLowerCase().contains('open');
    }

    return false;
  }

  /// Get price level as int for sorting
  int _getPriceLevel(dynamic priceLevel) {
    if (priceLevel == null) return 0;

    if (priceLevel is int) {
      return priceLevel;
    } else if (priceLevel is String) {
      return int.tryParse(priceLevel) ?? 0;
    } else if (priceLevel is double) {
      return priceLevel.round();
    }

    return 0;
  }

  /// ✅ Address dialog from place_details_screen.dart
  void _showAddressOptions(BuildContext context) {
    final restaurant = _selectedRestaurant;
    if (restaurant == null) return;

    final address = restaurant['address'] as String?;
    final double lat = (restaurant['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (restaurant['longitude'] as num?)?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C).withValues(alpha: 0.99),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.content_copy,
                  title: 'Copy address',
                  onTap: () {
                    Navigator.pop(context);
                    _copyAddress(address);
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.gps_fixed,
                  title: 'Copy GPS coordinates',
                  onTap: () {
                    Navigator.pop(context);
                    _copyCoordinates(lat, lng);
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.map,
                  title: 'Open in Apple Maps',
                  onTap: () {
                    Navigator.pop(context);
                    _openInAppleMaps(lat, lng);
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Open in Google Maps',
                  onTap: () {
                    Navigator.pop(context);
                    _openInGoogleMaps(lat, lng);
                  },
                ),
                const Divider(height: 1),
                _buildOptionTile(
                  context,
                  icon: Icons.close,
                  title: 'Cancel',
                  onTap: () => Navigator.pop(context),
                  isCancel: true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isCancel = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isCancel ? Colors.red : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isCancel ? Colors.red : Colors.white,
          fontWeight: isCancel ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }

  void _copyAddress(String? address) {
    if (address != null && address.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: address));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyCoordinates(double lat, double lng) {
    final coordinates = '$lat, $lng';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS coordinates copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openInAppleMaps(double lat, double lng) async {
    final url = Uri.parse('http://maps.apple.com?ll=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Apple Maps')),
      );
    }
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dark Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: _darkMapStyle,
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 300), () {
                _fitMapToMarkers();
              });
            },
            onTap: (_) {
              setState(() {
                _selectedRestaurant = null;
              });
              _createMarkers();
            },
          ),

          // Кнопка закрытия в левом верхнем углу
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // Google Logo (required by Google Maps policy)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ✅ Draggable Bottom Sheet - показывает либо список, либо детали
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.4, 0.9],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: _selectedRestaurant != null
                      ? _buildSelectedRestaurantDetails(scrollController)
                      : _buildRestaurantsList(scrollController),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// ✅ Детальная информация о выбранном ресторане
  Widget _buildSelectedRestaurantDetails(ScrollController scrollController) {
    final restaurant = _selectedRestaurant!;
    final category = restaurant['category'] as String?;
    final cuisine = restaurant['cuisine'] as String?;
    final rating = restaurant['rating'];
    final price = restaurant['price'] as String?;
    final description = restaurant['description'] as String?;
    final openingHours = _formatOpeningHours(restaurant['opening_hours']);
    final address = restaurant['address'] as String?;

    // Получаем все фотографии
    final List<String> images = [];
    if (restaurant['images'] != null && restaurant['images'] is List) {
      // ✅ Extract URL from image objects {url, source, alt_text}
      for (var img in restaurant['images'] as List) {
        if (img is Map && img['url'] != null) {
          final url = img['url'].toString();
          if (url.isNotEmpty) {
            images.add(url);
          }
        } else if (img is String && img.isNotEmpty) {
          // Fallback for string URLs
          images.add(img);
        }
      }
    } else if (restaurant['image_url'] != null) {
      images.add(restaurant['image_url'] as String);
    }

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        // ✅ Sticky Header: Handle + Back Button + Title
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyDetailHeaderDelegate(
            minHeight: 88,
            maxHeight: 88,
            child: Container(
              color: const Color(0xFF1C1C1E),
              child: Column(
                children: [
                  _buildSheetHandle(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant['name'] as String,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // "Add to trip" button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_circle_outline,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              if (widget.onRestaurantSelected != null) {
                                // Call the callback with selected restaurant
                                widget.onRestaurantSelected!(restaurant);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Add to trip functionality coming soon!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            padding: EdgeInsets.zero,
                            tooltip: widget.editingRestaurantId != null
                                ? 'Replace restaurant'
                                : 'Add to trip',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Back button (moved to right)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedRestaurant = null;
                                _selectedRestaurantIndex = null;
                                _selectedPhotoIndex = 0;
                              });
                              _createMarkers();
                              _sheetController.animateTo(
                                0.4,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            padding: EdgeInsets.zero,
                            tooltip: 'Close',
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

        // ✅ Photo Gallery с возможностью свайпа
        if (images.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Главная фотография со свайпом
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    controller: _photoPageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedPhotoIndex = index;
                      });
                    },
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildPlaceholderImage(category),
                            ),
                            // Индикатор количества фото
                            if (images.length > 1)
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${_selectedPhotoIndex + 1}/${images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // ✅ Горизонтальный список превью БЕЗ обводки
                if (images.length > 1)
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(top: 12),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedPhotoIndex;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPhotoIndex = index;
                            });
                            _photoPageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 80,
                            margin: EdgeInsets.only(
                              right: index < images.length - 1 ? 8 : 0,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.5,
                              child: Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderImage(category),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

        // ✅ Tabs: Overview, Menu, Reviews, Photos, Updates
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTabBarDelegate(
            minHeight: 50,
            maxHeight: 50,
            child: Container(
              color: const Color(0xFF1C1C1E),
              child: Row(
                children: [
                  _buildTab('Overview', 0),
                  _buildTab('Menu', 1),
                  _buildTab('Reviews', 2),
                  
                ],
              ),
            ),
          ),
        ),

        // Restaurant Details
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Rating, Price, Category
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (rating != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 19),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                  if (price != null) ...[
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                  if (cuisine != null && cuisine.isNotEmpty)
                    Text(
                      cuisine,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Category Badge
              if (category != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 17,
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCategoryLabel(category),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(category),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ✅ Content based on selected tab
              _buildTabContent(
                description: description,
                openingHours: openingHours,
                address: address,
                rating: rating as double?,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  /// ✅ Контент в зависимости от выбранного таба
  Widget _buildTabContent({
    String? description,
    String? openingHours,
    String? address,
    double? rating,
  }) {
    switch (_selectedTabIndex) {
      case 0: // Overview
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            if (description != null && description.isNotEmpty) ...[
              const Text(
                'About this place',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: _isDescriptionExpanded ? null : 3,
                      overflow: _isDescriptionExpanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ),
                  if (description.length > 100) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded ? 'See less' : 'See more',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ✅ Unified Info Block (Opening Hours + Address + Website + Price + Cuisine)
            _buildUnifiedInfoBlock(
              openingHours: _selectedRestaurant!['opening_hours'],
              address: address,
              website: _selectedRestaurant!['website'] as String?,
              price: _formatPriceLevel(_selectedRestaurant!['price_level']),
              cuisine: _formatCuisineTypes(_selectedRestaurant!['cuisine_types']),
            ),
            const SizedBox(height: 24),

            // ✅ Reviews Section Header
            const Text(
              'Ratings & reviews',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Reviews Section
            _buildReviewsSection(
              rating: rating,
              reviewCount: _selectedRestaurant!['review_count'] as int? ??
                  _selectedRestaurant!['google_review_count'] as int? ??
                  0,
            ),
            const SizedBox(height: 24),
          ],
        );

      case 1: // Menu
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Menu not available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          ),
        );

      case 2: // Reviews
        return _buildReviewsSection(
          rating: rating,
          reviewCount: _selectedRestaurant!['review_count'] as int? ??
              _selectedRestaurant!['google_review_count'] as int? ??
              0,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// ✅ Reviews Section with rating breakdown
  Widget _buildReviewsSection({
    required double? rating,
    required int reviewCount,
  }) {
    if (rating == null || rating == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No ratings available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Summary Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Large Rating Number
              Column(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < rating.floor()
                            ? Icons.star
                            : (index < rating ? Icons.star_half : Icons.star_border),
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$reviewCount reviews',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),

              // Rating Breakdown
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.7, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(4, 0.2, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(3, 0.07, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(2, 0.02, reviewCount),
                    const SizedBox(height: 8),
                    _buildRatingBar(1, 0.01, reviewCount),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build rating bar with percentage
  Widget _buildRatingBar(int stars, double percentage, int totalReviews) {
    final count = (totalReviews * percentage).round();

    return Row(
      children: [
        Text(
          '$stars',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            count > 0 ? '$count' : '',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// ✅ Unified Info Block - combines opening hours, address, and website
  Widget _buildUnifiedInfoBlock({
    required dynamic openingHours,
    required String? address,
    required String? website,
    String? price,
    String? cuisine,
  }) {
    final hasAddress = address != null && address.isNotEmpty;
    final hasWebsite = website != null && website.isNotEmpty;
    final hasPrice = price != null && price.isNotEmpty;
    final hasCuisine = cuisine != null && cuisine.isNotEmpty;

    // Build list of sections
    final List<Widget> sections = [];

    // Opening Hours
    sections.add(_buildOpeningHoursSectionCompact(openingHours));

    // Price
    if (hasPrice) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(_buildPriceSectionCompact(price));
    }

    // Cuisine
    if (hasCuisine) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(_buildCuisineSectionCompact(cuisine));
    }

    // Address
    if (hasAddress) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(_buildAddressSectionCompact(address));
    }

    // Website
    if (hasWebsite) {
      sections.add(Container(
        height: 5,
        color: const Color(0xFF1C1C1E),
      ));
      sections.add(_buildWebsiteSectionCompact(website));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: sections),
    );
  }

  /// ✅ Opening Hours Section (compact version without container)
  Widget _buildOpeningHoursSectionCompact(dynamic openingHours) {
    final openingStatus = _getOpeningStatus(openingHours);
    final weekdayHours = _getWeekdayHours(openingHours);
    final hasHours = weekdayHours.isNotEmpty;

    // Determine icon color based on status
    Color iconColor;
    Color textColor;
    if (openingStatus.toLowerCase().contains('closed')) {
      iconColor = Colors.red;
      textColor = Colors.red;
    } else if (openingStatus.toLowerCase().contains('open')) {
      iconColor = Colors.green;
      textColor = Colors.green;
    } else {
      // For time strings like "9:00 - 18:00"
      iconColor = Colors.white70;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: hasHours
          ? () {
              setState(() {
                _isOpeningHoursExpanded = !_isOpeningHoursExpanded;
              });
            }
          : null,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    openingStatus,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (hasHours)
                  Icon(
                    _isOpeningHoursExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 24,
                  ),
              ],
            ),
            if (_isOpeningHoursExpanded && hasHours) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF3C3C3E)),
              const SizedBox(height: 12),
              ...weekdayHours.map((dayHours) {
                final parts = dayHours.split(':');
                final day = parts[0].trim();
                final hours =
                    parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        hours,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ Address Section (compact version without container)
  Widget _buildAddressSectionCompact(String address) {
    return GestureDetector(
      onTap: () => _showAddressOptions(context),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Website Section (compact version without container)
  Widget _buildWebsiteSectionCompact(String website) {
    String displayUrl = website;
    try {
      final uri = Uri.parse(website);
      displayUrl = uri.host.replaceAll('www.', '');
    } catch (_) {}

    return GestureDetector(
      onTap: () => _openWebsite(website),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.language,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayUrl,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: Colors.white.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Price Section (compact version without container)
  Widget _buildPriceSectionCompact(String price) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.euro,
            color: Colors.green,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Price - ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '$price per person',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
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

  /// Cuisine Section (compact version without container)
  Widget _buildCuisineSectionCompact(String cuisine) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_menu,
            color: Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Cuisine - ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: cuisine,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
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

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }


  /// ✅ Список всех ресторанов (оригинальный вид)
  Widget _buildRestaurantsList(ScrollController scrollController) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            minHeight: 140,
            maxHeight: 140,
            child: Container(
              color: const Color(0xFF1C1C1E),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSheetHandle(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Restaurants',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFiltersRow(),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final filteredRestaurants = _getFilteredRestaurants();
                final restaurant = filteredRestaurants[index];
                final isSelected = _selectedRestaurantIndex == index;
                return _buildRestaurantCard(restaurant, isSelected, index);
              },
              childCount: _getFilteredRestaurants().length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 60,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildFilterChip(
                icon: Icons.access_time,
                label: 'Open now',
                isActive: _openNowFilter,
                onTap: () {
                  setState(() {
                    _openNowFilter = !_openNowFilter;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildPriceFilterChip(),
              const SizedBox(width: 8),
              _buildFilterChip(
                icon: Icons.star,
                label: 'Top rated',
                isActive: _topRatedFilter,
                onTap: () {
                  setState(() {
                    _topRatedFilter = !_topRatedFilter;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildCuisineFilterChip(),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    IconData? trailingIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFilterChip() {
    IconData? trailingIcon;
    if (_priceSortOrder == 'asc') {
      trailingIcon = Icons.arrow_downward;
    } else if (_priceSortOrder == 'desc') {
      trailingIcon = Icons.arrow_upward;
    }

    return _buildFilterChip(
      icon: Icons.euro,
      label: 'Price',
      isActive: _priceSortOrder != null,
      trailingIcon: trailingIcon,
      onTap: () {
        setState(() {
          if (_priceSortOrder == null) {
            _priceSortOrder = 'asc'; // First click: cheap to expensive
          } else if (_priceSortOrder == 'asc') {
            _priceSortOrder = 'desc'; // Second click: expensive to cheap
          } else {
            _priceSortOrder = null; // Third click: reset
          }
        });
      },
    );
  }

  Widget _buildCuisineFilterChip() {
    final cuisines = _getAvailableCuisines();

    return _buildFilterChip(
      icon: Icons.restaurant_menu,
      label: _selectedCuisine ?? 'Cuisine',
      isActive: _selectedCuisine != null,
      onTap: () {
        if (cuisines.isEmpty) return;

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C).withValues(alpha: 0.99),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Select Cuisine',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_selectedCuisine != null)
                      ListTile(
                        leading: const Icon(Icons.clear, color: Colors.red),
                        title: const Text(
                          'Clear filter',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCuisine = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ...cuisines.map((cuisine) => ListTile(
                          leading: Icon(
                            Icons.restaurant,
                            color: _selectedCuisine == cuisine
                                ? AppColors.primary
                                : Colors.white70,
                          ),
                          title: Text(
                            cuisine,
                            style: TextStyle(
                              color: _selectedCuisine == cuisine
                                  ? AppColors.primary
                                  : Colors.white,
                              fontWeight: _selectedCuisine == cuisine
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedCuisine = cuisine;
                            });
                            Navigator.pop(context);
                          },
                        )),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(
      Map<String, dynamic> restaurant, bool isSelected, int index) {
    final category = restaurant['category'] as String?;
    final cuisine = restaurant['cuisine'] as String?;
    final restaurantId = restaurant['poi_id']?.toString() ?? restaurant['name'];
    final isBeingEdited = widget.editingRestaurantId == restaurantId;
    final filteredRestaurants = _getFilteredRestaurants();

    return Column(
      children: [
        // Thin divider line before first restaurant
        if (index == 0)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        GestureDetector(
          onTap: () => _onMarkerTapped(restaurant, index),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isBeingEdited)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Editing',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (restaurant['rating'] != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${restaurant['rating']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 15),
                        ],
                      ),
                      Text(
                        '·',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                    if (restaurant['price'] != null) ...[
                      Text(
                        restaurant['price'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '·',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                    if (cuisine != null && cuisine.isNotEmpty)
                      Text(
                        cuisine,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getCategoryLabel(category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(category),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (restaurant['opening_hours'] != null)
                      Expanded(
                        child: Text(
                          _getOpeningStatus(restaurant['opening_hours']),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getOpeningStatus(restaurant['opening_hours'])
                                    .toLowerCase()
                                    .contains('open')
                                ? Colors.green
                                : (_getOpeningStatus(restaurant['opening_hours'])
                                        .toLowerCase()
                                        .contains('closed')
                                    ? Colors.red
                                    : Colors.white.withValues(alpha: 0.6)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (restaurant['image_url'] != null || restaurant['images'] != null)
                  SizedBox(
                    height: 100,
                    child: _buildPhotoGallery(restaurant),
                  ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    // Directions button (always shown)
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.directions,
                        label: 'Directions',
                        onTap: () {
                          final lat = (restaurant['latitude'] as num?)?.toDouble();
                          final lng = (restaurant['longitude'] as num?)?.toDouble();
                          if (lat != null && lng != null) {
                            _openDirections(lat, lng);
                          }
                        },
                      ),
                    ),
                    // Website button (only if website exists)
                    if (restaurant['website'] != null &&
                        (restaurant['website'] as String).isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.language,
                          label: 'Website',
                          onTap: () {
                            _openWebsite(restaurant['website'] as String?);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // Thin divider line
        if (index < filteredRestaurants.length - 1)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
      ],
    );
  }

  Widget _buildPhotoGallery(Map<String, dynamic> restaurant) {
    final List<String> images = [];

    if (restaurant['images'] != null && restaurant['images'] is List) {
      // ✅ Extract URL from image objects {url, source, alt_text}
      for (var img in restaurant['images'] as List) {
        if (img is Map && img['url'] != null) {
          final url = img['url'].toString();
          if (url.isNotEmpty) {
            images.add(url);
          }
        } else if (img is String && img.isNotEmpty) {
          // Fallback for string URLs
          images.add(img);
        }
      }
    } else if (restaurant['image_url'] != null) {
      images.add(restaurant['image_url'] as String);
    }

    if (images.isEmpty) {
      return _buildPlaceholderImage(restaurant['category'] as String?);
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Container(
          width: 140,
          margin: EdgeInsets.only(right: index < images.length - 1 ? 8 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withValues(alpha: 0.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholderImage(
              restaurant['category'] as String?,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage(String? category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(category),
          size: 40,
          color: _getCategoryColor(category),
        ),
      ),
    );
  }
}

// ✅ Sticky Header Delegate для списка ресторанов
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// ✅ Sticky Header для деталей ресторана (название + back button)
class _StickyDetailHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyDetailHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyDetailHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// ✅ Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyTabBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
