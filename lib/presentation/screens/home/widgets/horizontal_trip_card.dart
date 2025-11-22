import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/models/trip_model.dart';
import 'trip_details_bottom_sheet.dart';

class HorizontalTripCard extends StatefulWidget {
  final dynamic trip;
  final bool isDarkMode;

  const HorizontalTripCard({
    super.key,
    required this.trip,
    required this.isDarkMode,
  });

  @override
  State<HorizontalTripCard> createState() => _HorizontalTripCardState();
}

class _HorizontalTripCardState extends State<HorizontalTripCard> {
  bool _isFavorite = false;

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

  String _getImageUrl() {
    if (widget.trip is Trip) {
      final trip = widget.trip as Trip;
      return trip.heroImageUrl ?? trip.primaryImageUrl ?? '';
    } else if (widget.trip is TripModel) {
      final trip = widget.trip as TripModel;
      return trip.imageUrl ?? '';
    }
    return '';
  }

  String _getTitle() {
    if (widget.trip is Trip) {
      return (widget.trip as Trip).title;
    } else if (widget.trip is TripModel) {
      return (widget.trip as TripModel).title;
    }
    return '';
  }

  String _getLocation() {
    if (widget.trip is Trip) {
      final trip = widget.trip as Trip;
      return '${trip.city}, ${trip.country}';
    } else if (widget.trip is TripModel) {
      final trip = widget.trip as TripModel;
      return '${trip.city}, ${trip.country}';
    }
    return '';
  }

  String _getDuration() {
    if (widget.trip is Trip) {
      return (widget.trip as Trip).duration ?? '';
    } else if (widget.trip is TripModel) {
      return (widget.trip as TripModel).duration ?? '';
    }
    return '';
  }

  String _getPrice() {
    if (widget.trip is Trip) {
      return (widget.trip as Trip).price ?? '';
    } else if (widget.trip is TripModel) {
      return (widget.trip as TripModel).price ?? '';
    }
    return '';
  }

  double _getRating() {
    if (widget.trip is Trip) {
      return (widget.trip as Trip).rating ?? 0.0;
    } else if (widget.trip is TripModel) {
      return (widget.trip as TripModel).rating ?? 0.0;
    }
    return 0.0;
  }

  String _getActivityType() {
    if (widget.trip is Trip) {
      return (widget.trip as Trip).activityType;
    } else if (widget.trip is TripModel) {
      return (widget.trip as TripModel).activityType ?? '';
    }
    return '';
  }

  String _formatActivityType(String activityType) {
    if (activityType.isEmpty) return '';
    // Capitalize first letter and handle special cases
    final formatted = activityType.toLowerCase();
    if (formatted == 'road_trip') return 'Road Trip';
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    final title = _getTitle();
    final location = _getLocation();
    final duration = _getDuration();
    final price = _getPrice();
    final rating = _getRating();
    final activityType = _formatActivityType(_getActivityType());

    return GestureDetector(
      onTap: _onTripTap,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlays
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Main image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/300x240',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
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
                  ),

                  // Favorite button (top right)
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
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 22,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? Colors.white : AppColors.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Activity type and Duration
            Row(
              children: [
                if (activityType.isNotEmpty) ...[
                  Text(
                    activityType,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (duration.isNotEmpty) ...[
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
                if (duration.isNotEmpty)
                  Expanded(
                    child: Text(
                      duration,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.white.withOpacity(0.7) : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),

            // Price and Rating
            Row(
              children: [
                Expanded(
                  child: Text(
                    price,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: widget.isDarkMode ? Colors.white : AppColors.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (rating > 0) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.star,
                    size: 13,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: widget.isDarkMode ? Colors.white : AppColors.text,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
