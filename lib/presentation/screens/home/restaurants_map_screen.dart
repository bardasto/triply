// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/color_constants.dart';
// import '../../../providers/trip_provider.dart';
// import 'widgets/place_details_screen.dart';

// class RestaurantsMapScreen extends StatefulWidget {
//   const RestaurantsMapScreen({super.key});

//   @override
//   State<RestaurantsMapScreen> createState() => _RestaurantsMapScreenState();
// }

// class _RestaurantsMapScreenState extends State<RestaurantsMapScreen> {
//   GoogleMapController? _mapController;
//   Set<Marker> _markers = {};
//   List<Map<String, dynamic>> _allRestaurants = [];
//   Map<String, dynamic>? _selectedRestaurant;
//   String? _selectedTripFilter;
//   final DraggableScrollableController _sheetController =
//       DraggableScrollableController();

//   static const LatLng _defaultCenter = LatLng(48.8566, 2.3522); // Paris
//   static const double _headerHeight = 80.0; // Height of static header

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadRestaurants();
//     });
//   }

//   @override
//   void dispose() {
//     _mapController?.dispose();
//     _sheetController.dispose();
//     super.dispose();
//   }

//   /// Extract all restaurants from all trips
//   void _loadRestaurants() {
//     final tripProvider = context.read<TripProvider>();
//     final allTrips = [
//       ...tripProvider.nearbyTrips,
//       ...tripProvider.featuredTrips
//     ];

//     final List<Map<String, dynamic>> restaurants = [];
//     final Set<String> seenRestaurantIds = {};

//     for (var trip in allTrips) {
//       final tripData =
//           trip is Map<String, dynamic> ? trip : (trip as dynamic).toJson();

//       final itinerary = tripData['itinerary'] as List?;
//       if (itinerary == null) continue;

//       for (var day in itinerary) {
//         final places = day['places'] as List?;
//         if (places == null) continue;

//         for (var place in places) {
//           final category = place['category'] as String?;

//           // Only include restaurants (breakfast, lunch, dinner)
//           if (category == 'breakfast' ||
//               category == 'lunch' ||
//               category == 'dinner') {
//             final placeId = place['poi_id']?.toString() ?? place['name'];

//             // Avoid duplicates
//             if (!seenRestaurantIds.contains(placeId)) {
//               seenRestaurantIds.add(placeId);

//               // Add trip context
//               final restaurantWithContext = Map<String, dynamic>.from(place);
//               restaurantWithContext['trip_city'] = tripData['city'];
//               restaurantWithContext['trip_country'] = tripData['country'];
//               restaurantWithContext['trip_id'] = tripData['id'];

//               restaurants.add(restaurantWithContext);
//             }
//           }
//         }
//       }
//     }

//     setState(() {
//       _allRestaurants = restaurants;
//       _createMarkers();
//       _fitMapToMarkers();
//     });
//   }

//   /// Create markers for all restaurants
//   void _createMarkers() {
//     final markers = <Marker>{};

//     for (int i = 0; i < _allRestaurants.length; i++) {
//       final restaurant = _allRestaurants[i];
//       final lat = (restaurant['latitude'] as num?)?.toDouble();
//       final lng = (restaurant['longitude'] as num?)?.toDouble();

//       if (lat == null || lng == null) continue;

//       final isSelected = _selectedRestaurant != null &&
//           (restaurant['poi_id']?.toString() ?? restaurant['name']) ==
//               (_selectedRestaurant!['poi_id']?.toString() ??
//                   _selectedRestaurant!['name']);

//       markers.add(
//         Marker(
//           markerId: MarkerId('restaurant_$i'),
//           position: LatLng(lat, lng),
//           icon: isSelected
//               ? BitmapDescriptor.defaultMarkerWithHue(
//                   BitmapDescriptor.hueOrange)
//               : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           infoWindow: InfoWindow(
//             title: restaurant['name'] as String,
//             snippet: restaurant['address'] as String?,
//           ),
//           onTap: () => _onMarkerTapped(restaurant),
//         ),
//       );
//     }

//     setState(() {
//       _markers = markers;
//     });
//   }

//   /// Fit map bounds to show all markers
//   void _fitMapToMarkers() {
//     if (_allRestaurants.isEmpty || _mapController == null) return;

//     double? minLat, maxLat, minLng, maxLng;

//     for (var restaurant in _allRestaurants) {
//       final lat = (restaurant['latitude'] as num?)?.toDouble();
//       final lng = (restaurant['longitude'] as num?)?.toDouble();

//       if (lat == null || lng == null) continue;

//       minLat = minLat == null ? lat : (lat < minLat ? lat : minLat);
//       maxLat = maxLat == null ? lat : (lat > maxLat ? lat : maxLat);
//       minLng = minLng == null ? lng : (lng < minLng ? lng : minLng);
//       maxLng = maxLng == null ? lng : (lng > maxLng ? lng : maxLng);
//     }

//     if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
//       final bounds = LatLngBounds(
//         southwest: LatLng(minLat, minLng),
//         northeast: LatLng(maxLat, maxLng),
//       );

//       _mapController!.animateCamera(
//         CameraUpdate.newLatLngBounds(bounds, 50),
//       );
//     }
//   }

//   /// When marker is tapped
//   void _onMarkerTapped(Map<String, dynamic> restaurant) {
//     setState(() {
//       _selectedRestaurant = restaurant;
//       _createMarkers(); // Update marker colors
//     });

//     // Scroll bottom sheet to show the selected restaurant
//     _sheetController.animateTo(
//       0.4,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//     );
//   }

//   /// When restaurant card is tapped
//   void _onRestaurantTapped(Map<String, dynamic> restaurant) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (_) => PlaceDetailsScreen(
//           place: restaurant,
//           isDark: true,
//         ),
//       ),
//     );
//   }

//   /// Filter restaurants by trip
//   List<Map<String, dynamic>> get _filteredRestaurants {
//     if (_selectedTripFilter == null) {
//       return _allRestaurants;
//     }
//     return _allRestaurants
//         .where((r) => r['trip_id'] == _selectedTripFilter)
//         .toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final safeTop = MediaQuery.of(context).padding.top;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Google Map
//           GoogleMap(
//             initialCameraPosition: const CameraPosition(
//               target: _defaultCenter,
//               zoom: 12,
//             ),
//             markers: _markers,
//             myLocationButtonEnabled: false,
//             zoomControlsEnabled: false,
//             mapToolbarEnabled: false,
//             onMapCreated: (controller) {
//               _mapController = controller;
//               _fitMapToMarkers();
//             },
//             onTap: (_) {
//               // Deselect restaurant when tapping on map
//               setState(() {
//                 _selectedRestaurant = null;
//                 _createMarkers();
//               });
//             },
//           ),

//           // Draggable Bottom Sheet with Static Header
//           DraggableScrollableSheet(
//             controller: _sheetController,
//             initialChildSize: 0.3,
//             minChildSize: 0.15,
//             maxChildSize: 0.85,
//             snap: true,
//             snapSizes: const [0.15, 0.3, 0.85],
//             builder: (context, scrollController) {
//               return Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1E1E1E),
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(24),
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withValues(alpha: 0.3),
//                       blurRadius: 20,
//                       offset: const Offset(0, -4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     // ✅ Static Header (не скроллится)
//                     _buildStaticHeader(),

//                     // ✅ Scrollable Content
//                     Expanded(
//                       child: NotificationListener<ScrollNotification>(
//                         onNotification: (notification) {
//                           // ✅ Блокируем скролл вниз, когда sheet в начальной позиции
//                           if (notification is ScrollUpdateNotification) {
//                             if (scrollController.position.pixels <= 0 &&
//                                 notification.scrollDelta! < 0) {
//                               return true; // Блокируем скролл вниз
//                             }
//                           }
//                           return false;
//                         },
//                         child: _buildRestaurantList(scrollController),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),

//           // Back Button
//           Positioned(
//             top: safeTop + 12,
//             left: 16,
//             child: _buildBackButton(),
//           ),

//           // Filter Button
//           if (_allRestaurants.isNotEmpty)
//             Positioned(
//               top: safeTop + 12,
//               right: 16,
//               child: _buildFilterButton(),
//             ),
//         ],
//       ),
//     );
//   }

//   /// ✅ Static Header (всегда видимый)
//   Widget _buildStaticHeader() {
//     return Container(
//       height: _headerHeight,
//       decoration: const BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: Colors.white12, width: 1),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Handle
//           Container(
//             margin: const EdgeInsets.only(top: 12, bottom: 8),
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.3),
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),

//           // Header Content
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Icons.restaurant,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       _selectedTripFilter == null
//                           ? 'Restaurants (${_filteredRestaurants.length})'
//                           : 'Filtered (${_filteredRestaurants.length})',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   if (_selectedTripFilter != null)
//                     IconButton(
//                       icon: const Icon(Icons.clear, color: Colors.white70),
//                       padding: EdgeInsets.zero,
//                       constraints: const BoxConstraints(),
//                       onPressed: () {
//                         setState(() {
//                           _selectedTripFilter = null;
//                         });
//                       },
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRestaurantList(ScrollController scrollController) {
//     final restaurants = _filteredRestaurants;

//     if (restaurants.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.restaurant_menu,
//               size: 64,
//               color: Colors.white.withValues(alpha: 0.3),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'No restaurants found',
//               style: TextStyle(
//                 fontSize: 18,
//                 color: Colors.white.withValues(alpha: 0.6),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.builder(
//       controller: scrollController,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       itemCount: restaurants.length,
//       itemBuilder: (context, index) {
//         final restaurant = restaurants[index];
//         final isSelected = _selectedRestaurant != null &&
//             (restaurant['poi_id']?.toString() ?? restaurant['name']) ==
//                 (_selectedRestaurant!['poi_id']?.toString() ??
//                     _selectedRestaurant!['name']);

//         return _buildRestaurantCard(restaurant, isSelected);
//       },
//     );
//   }

//   Widget _buildRestaurantCard(
//       Map<String, dynamic> restaurant, bool isSelected) {
//     return GestureDetector(
//       onTap: () => _onRestaurantTapped(restaurant),
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.primary.withValues(alpha: 0.15)
//               : Colors.white.withValues(alpha: 0.05),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected
//                 ? AppColors.primary.withValues(alpha: 0.5)
//                 : Colors.white.withValues(alpha: 0.1),
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             // Restaurant Image or Icon
//             _buildRestaurantImage(restaurant),
//             const SizedBox(width: 16),

//             // Restaurant Info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     restaurant['name'] as String,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   if (restaurant['category'] != null)
//                     Text(
//                       _getCategoryLabel(restaurant['category'] as String),
//                       style: TextStyle(
//                         fontSize: 12,
//                         color:
//                             _getCategoryColor(restaurant['category'] as String),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       if (restaurant['rating'] != null) ...[
//                         const Icon(Icons.star, color: Colors.amber, size: 16),
//                         const SizedBox(width: 4),
//                         Text(
//                           restaurant['rating'].toString(),
//                           style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.amber,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                       ],
//                       if (restaurant['price'] != null) ...[
//                         const Icon(Icons.euro, color: Colors.green, size: 14),
//                         const SizedBox(width: 2),
//                         Text(
//                           restaurant['price'] as String,
//                           style: const TextStyle(
//                               fontSize: 13, color: Colors.green),
//                         ),
//                       ],
//                     ],
//                   ),
//                   if (restaurant['trip_city'] != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 6),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.location_on,
//                               size: 14, color: Colors.redAccent),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${restaurant['trip_city']}, ${restaurant['trip_country'] ?? ''}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.white.withValues(alpha: 0.6),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             // Arrow Icon
//             Icon(
//               Icons.chevron_right,
//               color: Colors.white.withValues(alpha: 0.4),
//               size: 24,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRestaurantImage(Map<String, dynamic> restaurant) {
//     final imageUrl = restaurant['image_url'] as String?;
//     final category = restaurant['category'] as String? ?? 'dinner';

//     return Container(
//       width: 70,
//       height: 70,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.white.withValues(alpha: 0.1),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: imageUrl != null && imageUrl.isNotEmpty
//           ? Image.network(
//               imageUrl,
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) => _getCategoryIcon(category),
//             )
//           : _getCategoryIcon(category),
//     );
//   }

//   Widget _getCategoryIcon(String category) {
//     IconData icon;
//     Color color;

//     switch (category) {
//       case 'breakfast':
//         icon = Icons.free_breakfast;
//         color = Colors.orange;
//         break;
//       case 'lunch':
//         icon = Icons.lunch_dining;
//         color = Colors.amber;
//         break;
//       case 'dinner':
//         icon = Icons.dinner_dining;
//         color = Colors.red;
//         break;
//       default:
//         icon = Icons.restaurant;
//         color = AppColors.primary;
//     }

//     return Center(
//       child: Icon(icon, size: 32, color: color),
//     );
//   }

//   String _getCategoryLabel(String category) {
//     switch (category) {
//       case 'breakfast':
//         return 'Breakfast';
//       case 'lunch':
//         return 'Lunch';
//       case 'dinner':
//         return 'Dinner';
//       default:
//         return 'Restaurant';
//     }
//   }

//   Color _getCategoryColor(String category) {
//     switch (category) {
//       case 'breakfast':
//         return Colors.orange;
//       case 'lunch':
//         return Colors.amber;
//       case 'dinner':
//         return Colors.red;
//       default:
//         return AppColors.primary;
//     }
//   }

//   Widget _buildBackButton() {
//     return GestureDetector(
//       onTap: () => Navigator.of(context).pop(),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.black.withValues(alpha: 0.5),
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.2),
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: ClipOval(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: const Icon(
//               Icons.arrow_back_ios_new_rounded,
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterButton() {
//     return GestureDetector(
//       onTap: _showFilterDialog,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: _selectedTripFilter != null
//               ? AppColors.primary.withValues(alpha: 0.9)
//               : Colors.black.withValues(alpha: 0.5),
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.2),
//               blurRadius: 8,
//             ),
//           ],
//         ),
//         child: ClipOval(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Icon(
//               _selectedTripFilter != null
//                   ? Icons.filter_alt
//                   : Icons.filter_alt_outlined,
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showFilterDialog() {
//     final tripProvider = context.read<TripProvider>();
//     final allTrips = [
//       ...tripProvider.nearbyTrips,
//       ...tripProvider.featuredTrips
//     ];

//     // Get unique trips
//     final uniqueTrips = <String, Map<String, dynamic>>{};
//     for (var trip in allTrips) {
//       final tripData =
//           trip is Map<String, dynamic> ? trip : (trip as dynamic).toJson();
//       final tripId = tripData['id']?.toString();
//       if (tripId != null && !uniqueTrips.containsKey(tripId)) {
//         uniqueTrips[tripId] = tripData;
//       }
//     }

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         decoration: BoxDecoration(
//           color: const Color(0xFF1E1E1E),
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const SizedBox(height: 12),
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withValues(alpha: 0.3),
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Text(
//                   'Filter by Trip',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               const Divider(height: 1, color: Colors.white12),
//               ListTile(
//                 leading: const Icon(Icons.clear_all, color: AppColors.primary),
//                 title: const Text(
//                   'Show All Restaurants',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() {
//                     _selectedTripFilter = null;
//                   });
//                 },
//               ),
//               const Divider(height: 1, color: Colors.white12),
//               ...uniqueTrips.entries.map((entry) {
//                 final tripData = entry.value;
//                 return ListTile(
//                   leading:
//                       const Icon(Icons.location_city, color: Colors.white70),
//                   title: Text(
//                     tripData['title'] ?? tripData['city'] ?? 'Unknown',
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                   subtitle: Text(
//                     '${tripData['city']}, ${tripData['country']}',
//                     style:
//                         TextStyle(color: Colors.white.withValues(alpha: 0.6)),
//                   ),
//                   selected: _selectedTripFilter == entry.key,
//                   selectedTileColor: AppColors.primary.withValues(alpha: 0.2),
//                   onTap: () {
//                     Navigator.pop(context);
//                     setState(() {
//                       _selectedTripFilter = entry.key;
//                     });
//                   },
//                 );
//               }),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
