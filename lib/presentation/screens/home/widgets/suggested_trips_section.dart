import 'dart:ui';

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
              final trips = _getFilteredTrips(tripProvider);
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

class _TripCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _TripImage(
                imageUrl: trip is Trip
                    ? trip.primaryImageUrl
                    : (trip is TripModel ? trip.imageUrl : null),
              ),
              _ImageGradient(),
              if (distance != null)
                _DistanceBadge(
                  distance: distance!,
                  formatDistance: formatDistance,
                ),
              _TripInfoCard(trip: trip),
            ],
          ),
        ),
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

class _ImageGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final double distance;
  final String Function(double) formatDistance;

  const _DistanceBadge({
    required this.distance,
    required this.formatDistance,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  formatDistance(distance),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripInfoCard extends StatelessWidget {
  final dynamic trip;

  const _TripInfoCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 30,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trip is Trip
                      ? trip.title
                      : (trip is TripModel ? trip.title : ''),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _TripMetadata(trip: trip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripMetadata extends StatelessWidget {
  final dynamic trip;

  const _TripMetadata({required this.trip});

  @override
  Widget build(BuildContext context) {
    final duration =
        trip is Trip ? trip.duration : (trip is TripModel ? trip.duration : '');
    final rating =
        trip is Trip ? trip.rating : (trip is TripModel ? trip.rating : 0.0);
    final price =
        trip is Trip ? trip.price : (trip is TripModel ? trip.price : '');

    return Row(
      children: [
        _MetadataBadge(
          icon: Icons.access_time,
          text: duration,
          iconColor: Colors.white,
        ),
        const SizedBox(width: 6),
        _MetadataBadge(
          icon: Icons.star,
          text: rating.toStringAsFixed(1),
          iconColor: Colors.amber,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  blurRadius: 4,
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _MetadataBadge({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: iconColor,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
