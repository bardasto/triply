import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/color_constants.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/trip_model.dart';
import '../../../../providers/trip_provider.dart';
import 'trip_details_bottom_sheet.dart';

class SuggestedTripsSection extends StatelessWidget {
  final bool isDarkMode;
  final String? continent;
  final String? activityType;
  final bool useNearbyTrips;

  const SuggestedTripsSection({
    super.key,
    required this.isDarkMode,
    this.continent,
    this.activityType,
    this.useNearbyTrips = false,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ HELPER METHODS
  // ══════════════════════════════════════════════════════════════════════════
  List<dynamic> _getFilteredTrips(TripProvider provider) {
    var trips = useNearbyTrips ? provider.nearbyTrips : provider.featuredTrips;

    print('🎯 SuggestedTripsSection:');
    print('   - useNearbyTrips: $useNearbyTrips');
    print('   - nearbyTrips count: ${provider.nearbyTrips.length}');
    print('   - featuredTrips count: ${provider.featuredTrips.length}');
    print('   - selected trips count: ${trips.length}');
    print('   - activityType filter: $activityType');

    if (activityType != null && activityType!.isNotEmpty) {
      final filtered = trips.where((trip) {
        if (trip is Trip) {
          return trip.activityType.toLowerCase() == activityType!.toLowerCase();
        } else if (trip is TripModel) {
          return trip.activityType?.toLowerCase() ==
              activityType!.toLowerCase();
        }
        return false;
      }).toList();

      print('   - filtered count: ${filtered.length}');
      return filtered;
    }

    return trips;
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.round()} km';
    }
  }

  void _onTripTap(BuildContext context, dynamic trip) {
    Map<String, dynamic> tripData;

    if (trip is Trip) {
      // ✅ Конвертируем List<TripDay> в List<Map<String, dynamic>>
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
        'itinerary': itineraryData, // ✅ ИСПРАВЛЕНО!
        'image_url': trip.primaryImageUrl,
        'hero_image_url': trip.heroImageUrl ?? trip.primaryImageUrl,
        'city': trip.city,
        'country': trip.country,
        'latitude': trip.latitude,
        'longitude': trip.longitude,
      };

      // ✅ DEBUG
      print('═══════════════════════════════════════════════════════');
      print('🎯 Trip tapped: ${trip.title}');
      print('📋 Has itinerary: ${trip.itinerary != null}');
      print('📋 Itinerary length: ${trip.itinerary?.length ?? 0}');
      print('📋 Converted itinerary length: ${itineraryData.length}');
      if (itineraryData.isNotEmpty) {
        print('📋 First day data: ${itineraryData[0]}');
      }
      print('═══════════════════════════════════════════════════════');
    } else if (trip is TripModel) {
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
      isDarkMode: isDarkMode,
    );
  }


  // ══════════════════════════════════════════════════════════════════════════
  // ✅ BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            useNearbyTrips: useNearbyTrips,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 16),
          Consumer<TripProvider>(
            builder: (context, tripProvider, _) {
              // If searching, show search results instead
              if (tripProvider.isSearching) {
                return const _LoadingIndicator();
              }

              final trips = tripProvider.searchResults.isNotEmpty
                  ? tripProvider.searchResults
                  : _getFilteredTrips(tripProvider);

              final isLoading = useNearbyTrips
                  ? tripProvider.isLoadingLocation
                  : tripProvider.isLoading;

              if (isLoading && trips.isEmpty) {
                return const _LoadingIndicator();
              }

              if (trips.isEmpty) {
                return _EmptyState(
                  useNearbyTrips: useNearbyTrips,
                  activityType: activityType,
                  isDarkMode: isDarkMode,
                );
              }

              return Column(
                children: trips.map((trip) {
                  double? distance;
                  if (useNearbyTrips) {
                    if (trip is Trip) {
                      distance = tripProvider.getDistanceToPublicTrip(trip);
                    } else if (trip is TripModel) {
                      distance = tripProvider.getDistanceToLegacyTrip(trip);
                    }
                  }

                  return _TripCard(
                    trip: trip,
                    distance: distance,
                    onTap: () => _onTripTap(context, trip),
                    formatDistance: _formatDistance,
                    isDarkMode: isDarkMode,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ EXTRACTED WIDGETS (БЕЗ ИЗМЕНЕНИЙ)
// ══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final bool useNearbyTrips;
  final bool isDarkMode;

  const _SectionHeader({
    required this.useNearbyTrips,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          useNearbyTrips ? 'Nearby Places' : 'Suggested Trips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : AppColors.text,
          ),
        ),
        if (useNearbyTrips) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ],
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool useNearbyTrips;
  final String? activityType;
  final bool isDarkMode;

  const _EmptyState({
    required this.useNearbyTrips,
    required this.activityType,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              useNearbyTrips ? Icons.location_off : Icons.explore_off,
              size: 48,
              color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              activityType != null
                  ? 'No $activityType trips found nearby'
                  : useNearbyTrips
                      ? 'No nearby places found\nTry adjusting your location'
                      : 'No trips available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatefulWidget {
  final dynamic trip;
  final double? distance;
  final VoidCallback onTap;
  final String Function(double) formatDistance;
  final bool isDarkMode;

  const _TripCard({
    required this.trip,
    required this.distance,
    required this.onTap,
    required this.formatDistance,
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

  @override
  Widget build(BuildContext context) {
    // Extract images based on trip type
    List<String> images;
    if (widget.trip is Trip) {
      final trip = widget.trip as Trip;
      images = [];

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
                if (imageUrl != null && imageUrl.isNotEmpty && !images.contains(imageUrl)) {
                  images.add(imageUrl);
                  if (images.length >= 5) break; // Limit to 5 images
                }
              } else if (place.imageUrl != null && place.imageUrl!.isNotEmpty && !images.contains(place.imageUrl!)) {
                images.add(place.imageUrl!);
                if (images.length >= 5) break;
              }
            }
          }
          if (images.length >= 5) break;
        }
      }

      print('🖼️ [TRIP CARD] Trip: ${trip.title}');
      print('   - Hero image: ${trip.heroImageUrl}');
      print('   - trip.images count: ${trip.images?.length ?? 0}');
      print('   - Total images extracted: ${images.length}');
      if (images.isNotEmpty) {
        print('   - First image: ${images[0]}');
      }

    } else if (widget.trip is TripModel) {
      final tripModel = widget.trip as TripModel;
      images = tripModel.images ?? [];
    } else {
      images = [];
    }

    final title = widget.trip is Trip
        ? widget.trip.title
        : (widget.trip is TripModel ? widget.trip.title : '');

    final location = widget.trip is Trip
        ? '${widget.trip.city}, ${widget.trip.country}'
        : (widget.trip is TripModel
            ? '${widget.trip.city}, ${widget.trip.country}'
            : '');

    final duration = widget.trip is Trip
        ? widget.trip.duration
        : (widget.trip is TripModel ? widget.trip.duration : '');

    final price = widget.trip is Trip
        ? widget.trip.price
        : (widget.trip is TripModel ? widget.trip.price : '');

    final rating = widget.trip is Trip
        ? widget.trip.rating
        : (widget.trip is TripModel ? widget.trip.rating : 0.0);

    // NO GestureDetector wrapping the entire card - this allows PageView to work
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section with PageView for swiping photos
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // PageView for images (swipeable) with tap handler on each image
                  if (images.isNotEmpty)
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const AlwaysScrollableScrollPhysics(), // Ensure swiping works
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          // Each individual image has tap handler
                          return GestureDetector(
                            onTap: widget.onTap,
                            child: _TripImage(imageUrl: images[index]),
                          );
                        },
                      ),
                    )
                  else
                    // Single image with tap handler
                    GestureDetector(
                      onTap: widget.onTap,
                      child: _TripImage(imageUrl: null),
                    ),
                  // Page indicator - IgnorePointer so it doesn't block swipes
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                images.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPage == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.5),
                                    boxShadow: _currentPage == index
                                        ? [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(0.5),
                                              blurRadius: 4,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Favorite button - separate tap handler
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
                  // Distance badge - IgnorePointer so it doesn't block swipes
                  if (widget.distance != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.formatDistance(widget.distance!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // New badge - IgnorePointer so it doesn't block swipes
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'New',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Trip info - wrapped with GestureDetector for tap to open
          GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque, // Ensure entire area is tappable
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
                          color: widget.isDarkMode ? Colors.white : AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating > 0) ...[
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode ? Colors.white : AppColors.text,
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
                    if (duration.isNotEmpty) ...[
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
                        price,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.isDarkMode ? Colors.white : AppColors.text,
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

class _TripImage extends StatelessWidget {
  final String? imageUrl;

  const _TripImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl ?? 'https://via.placeholder.com/400x200',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }
}

