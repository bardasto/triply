import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'widgets/map/custom_marker_painter.dart';
import 'widgets/list/restaurants_list_view.dart';
import 'widgets/details/restaurant_details_sheet.dart';
import 'utils/map_utils.dart';

/// Fullscreen map view showing all restaurants from a trip
class FullscreenRestaurantsMap extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final bool isDark;
  final String? tripCity;
  final String? editingRestaurantId;
  final Function(Map<String, dynamic>)? onRestaurantSelected;

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
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _createMarkers() async {
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

      final customIcon = await CustomMarkerPainter.createMarkerWithRating(
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

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  void _onMarkerTapped(Map<String, dynamic> restaurant, int index) {
    setState(() {
      _selectedRestaurant = restaurant;
      _selectedRestaurantIndex = index;
    });
    _createMarkers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sheetController.animateTo(
          0.9,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    final lat = (restaurant['latitude'] as num?)?.toDouble();
    final lng = (restaurant['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16),
      );
    }
  }

  void _closeDetailsSheet() {
    setState(() {
      _selectedRestaurant = null;
      _selectedRestaurantIndex = null;
    });
    _createMarkers();
    _sheetController.animateTo(
      0.4,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: MapUtils.getInitialPosition(widget.restaurants),
              zoom: 15,
            ),
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: MapUtils.darkMapStyle,
            onMapCreated: (controller) {
              _mapController = controller;
              Future.delayed(const Duration(milliseconds: 300), () {
                MapUtils.fitMapToMarkers(_mapController, widget.restaurants);
              });
            },
            onTap: (_) {
              setState(() {
                _selectedRestaurant = null;
              });
              _createMarkers();
            },
          ),

          // Back button
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

          // Google Logo
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

          // Draggable Bottom Sheet
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
                      ? RestaurantDetailsSheet(
                          restaurant: _selectedRestaurant!,
                          scrollController: scrollController,
                          onClose: _closeDetailsSheet,
                          onAdd: widget.onRestaurantSelected != null
                              ? () {
                                  widget.onRestaurantSelected!(
                                      _selectedRestaurant!);
                                }
                              : null,
                        )
                      : RestaurantsListView(
                          restaurants: widget.restaurants,
                          scrollController: scrollController,
                          editingRestaurantId: widget.editingRestaurantId,
                          onRestaurantTapped: _onMarkerTapped,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
