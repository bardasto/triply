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
  final PageController _photoPageController = PageController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

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
    final openingHours = restaurant['opening_hours'] as String?;
    final address = restaurant['address'] as String?;

    // Получаем все фотографии
    final List<String> images = [];
    if (restaurant['images'] != null && restaurant['images'] is List) {
      images.addAll(
        (restaurant['images'] as List)
            .where((img) => img != null && img.toString().isNotEmpty)
            .map((img) => img.toString())
            .toList(),
      );
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
                              fontSize: 20,
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
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$rating',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                  if (price != null) ...[
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      '·',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                  if (cuisine != null && cuisine.isNotEmpty)
                    Text(
                      cuisine,
                      style: TextStyle(
                        fontSize: 16,
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
                        size: 16,
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCategoryLabel(category),
                        style: TextStyle(
                          fontSize: 14,
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Opening Hours
            if (openingHours != null && openingHours.isNotEmpty) ...[
              _buildInfoRow(
                Icons.access_time,
                'Hours',
                openingHours,
              ),
              const SizedBox(height: 16),
            ],

            // ✅ Address - кликабельный БЕЗ надписи "Address"
            if (address != null && address.isNotEmpty) ...[
              GestureDetector(
                onTap: () => _showAddressOptions(context),
                child: _buildInfoRow(
                  Icons.location_on,
                  '',
                  address,
                  isClickable: true,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ✅ Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.info_outline,
                    label: 'About',
                    onTap: () {
                      // Scroll to about section or show dialog
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.phone,
                    label: 'Call',
                    onTap: () {
                      // Call restaurant
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.directions,
                    label: 'Directions',
                    onTap: () => _showAddressOptions(context),
                  ),
                ),
              ],
            ),
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
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'Reviews not available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isClickable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (isClickable ? Colors.red : AppColors.primary)
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isClickable ? Colors.red : AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label.isNotEmpty) ...[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: isClickable
                      ? Colors.red
                      : Colors.white.withValues(alpha: 0.9),
                  decoration: isClickable
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        if (isClickable)
          Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.5),
          ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final restaurant = widget.restaurants[index];
                final isSelected = _selectedRestaurantIndex == index;
                return _buildRestaurantCard(restaurant, isSelected, index);
              },
              childCount: widget.restaurants.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 50,
      height: 6,
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
              _buildFilterChip(Icons.filter_list, 'Sort by', () {}),
              const SizedBox(width: 8),
              _buildFilterChip(Icons.access_time, 'Open now', () {}),
              const SizedBox(width: 8),
              _buildFilterChip(Icons.euro, 'Price', () {}),
              const SizedBox(width: 8),
              _buildFilterChip(Icons.star, 'Top rated', () {}),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFilterChip(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
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
          ],
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

    return GestureDetector(
      onTap: () => _onMarkerTapped(restaurant, index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2E) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBeingEdited
                ? Colors.orange.withValues(alpha: 0.6)
                : (isSelected
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.05)),
            width: isBeingEdited ? 2 : (isSelected ? 2 : 1),
          ),
        ),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                    ],
                  ),
                  Text(
                    '·',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
                if (restaurant['price'] != null) ...[
                  Text(
                    restaurant['price'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '·',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
                if (cuisine != null && cuisine.isNotEmpty)
                  Text(
                    cuisine,
                    style: TextStyle(
                      fontSize: 14,
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
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getCategoryLabel(category),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(category),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (restaurant['opening_hours'] != null)
                  Expanded(
                    child: Text(
                      restaurant['opening_hours'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
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
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery(Map<String, dynamic> restaurant) {
    final List<String> images = [];

    if (restaurant['images'] != null && restaurant['images'] is List) {
      images.addAll(
        (restaurant['images'] as List)
            .where((img) => img != null && img.toString().isNotEmpty)
            .map((img) => img.toString())
            .toList(),
      );
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
