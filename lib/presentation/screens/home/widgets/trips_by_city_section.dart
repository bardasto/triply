import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/trip_model.dart';
import '../../../../providers/trip_provider.dart';
import 'horizontal_trip_card.dart';
import '../../city_trips/city_trips_screen.dart';

class TripsByCitySection extends StatelessWidget {
  final bool isDarkMode;
  final String? activityType;

  const TripsByCitySection({
    super.key,
    required this.isDarkMode,
    this.activityType,
  });

  Map<String, List<dynamic>> _groupTripsByCity(List<dynamic> trips) {
    final Map<String, List<dynamic>> groupedTrips = {};

    // Filter by activity type first if specified
    List<dynamic> filteredTrips = trips;
    if (activityType != null && activityType!.isNotEmpty) {
      filteredTrips = trips.where((trip) {
        if (trip is Trip) {
          return trip.activityType.toLowerCase() == activityType!.toLowerCase();
        } else if (trip is TripModel) {
          return trip.activityType?.toLowerCase() == activityType!.toLowerCase();
        }
        return false;
      }).toList();
    }

    for (var trip in filteredTrips) {
      String city = '';
      if (trip is Trip) {
        city = trip.city ?? 'Unknown';
      } else if (trip is TripModel) {
        city = trip.city ?? 'Unknown';
      }

      if (city.isNotEmpty && city != 'Unknown') {
        if (!groupedTrips.containsKey(city)) {
          groupedTrips[city] = [];
        }
        groupedTrips[city]!.add(trip);
      }
    }

    return groupedTrips;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final trips = tripProvider.nearbyTrips;

        if (trips.isEmpty) {
          return const SizedBox.shrink();
        }

        final groupedTrips = _groupTripsByCity(trips);

        if (groupedTrips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedTrips.entries.map((entry) {
            final city = entry.key;
            final cityTrips = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City header with "See all" button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _BounceableButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CityTripsScreen(
                              cityName: city,
                              trips: cityTrips,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              activityType != null && activityType!.isNotEmpty
                                  ? '${_getActivityName(activityType!)} in $city'
                                  : 'Trip in $city',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : AppColors.text,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Horizontal scrolling list of trip cards
                  SizedBox(
                    height: 270,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cityTrips.length,
                      itemBuilder: (context, index) {
                        final trip = cityTrips[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index < cityTrips.length - 1 ? 16 : 0,
                          ),
                          child: HorizontalTripCard(
                            trip: trip,
                            isDarkMode: isDarkMode,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// BOUNCE ANIMATION WIDGET
// ══════════════════════════════════════════════════════════════════════════

class _BounceableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BounceableButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_BounceableButton> createState() => _BounceableButtonState();
}

class _BounceableButtonState extends State<_BounceableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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
      onTap: () {
        HapticFeedback.lightImpact();
        _controller.forward().then((_) => _controller.reverse());
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
