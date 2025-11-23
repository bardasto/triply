import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/services/ai_trips_storage_service.dart';
import '../home/widgets/trip_details_bottom_sheet.dart';

class AiTripsScreen extends StatefulWidget {
  const AiTripsScreen({super.key});

  @override
  State<AiTripsScreen> createState() => _AiTripsScreenState();
}

class _AiTripsScreenState extends State<AiTripsScreen> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  RealtimeChannel? _tripsChannel;

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _cleanupRealtimeSubscription();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final trips = await AiTripsStorageService.getAllTrips();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _isLoading = false;
    });
  }

  void _setupRealtimeSubscription() {
    try {
      _tripsChannel = AiTripsStorageService.subscribeToTrips((trips) {
        if (mounted) {
          setState(() {
            _trips = trips;
          });
        }
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }

  Future<void> _cleanupRealtimeSubscription() async {
    if (_tripsChannel != null) {
      await AiTripsStorageService.unsubscribeFromTrips(_tripsChannel!);
    }
  }

  Future<void> _deleteTrip(String tripId) async {
    await AiTripsStorageService.deleteTrip(tripId);
    // Realtime subscription will auto-update the list
  }

  Future<void> _toggleFavorite(String tripId, bool currentValue) async {
    await AiTripsStorageService.toggleFavorite(tripId, !currentValue);
    // Realtime subscription will auto-update the list
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.darkBackground,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      color: AppColors.darkBackground,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trip = _trips[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _TripCard(
                        trip: trip,
                        onDelete: () => _deleteTrip(trip['id']),
                        onToggleFavorite: () => _toggleFavorite(
                          trip['id'],
                          trip['is_favorite'] ?? false,
                        ),
                      ),
                    );
                  },
                  childCount: _trips.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My AI Trips',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_trips.length} ${_trips.length == 1 ? 'trip' : 'trips'}',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.darkBackground,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_travel_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'No trips yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start planning with AI Chat!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _TripCard({
    required this.trip,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
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
    TripDetailsBottomSheet.show(
      context,
      trip: widget.trip,
      isDarkMode: true,
    );
  }

  List<String> _getImages() {
    List<String> images = [];

    // 1. Hero image first
    final heroImage = widget.trip['hero_image_url'];
    if (heroImage != null && heroImage.toString().isNotEmpty) {
      images.add(heroImage.toString());
    }

    // 2. Get images from trip.images array
    final tripImages = widget.trip['images'];
    if (tripImages != null && tripImages is List) {
      for (var img in tripImages) {
        final url = img is String ? img : img['url']?.toString();
        if (url != null && url.isNotEmpty && !images.contains(url)) {
          images.add(url);
        }
      }
    }

    // 3. Extract from itinerary places (up to 5 total)
    if (images.length < 5) {
      final itinerary = widget.trip['itinerary'];
      if (itinerary != null && itinerary is List) {
        for (var day in itinerary) {
          final places = day['places'];
          if (places != null && places is List) {
            for (var place in places) {
              // Get from place images array
              final placeImages = place['images'];
              if (placeImages != null && placeImages is List && placeImages.isNotEmpty) {
                final imageUrl = placeImages[0] is String
                    ? placeImages[0]
                    : placeImages[0]['url']?.toString();
                if (imageUrl != null &&
                    imageUrl.isNotEmpty &&
                    !images.contains(imageUrl)) {
                  images.add(imageUrl);
                  if (images.length >= 5) break;
                }
              }
              // Fallback to image_url
              final imageUrl = place['image_url'];
              if (imageUrl != null &&
                  imageUrl.toString().isNotEmpty &&
                  !images.contains(imageUrl.toString())) {
                images.add(imageUrl.toString());
                if (images.length >= 5) break;
              }
            }
          }
          if (images.length >= 5) break;
        }
      }
    }

    return images;
  }

  @override
  Widget build(BuildContext context) {
    final images = _getImages();
    final title = widget.trip['title'] ?? widget.trip['name'] ?? 'Untitled Trip';
    final city = widget.trip['city'] ?? '';
    final country = widget.trip['country'] ?? '';
    final location = city.isNotEmpty && country.isNotEmpty
        ? '$city, $country'
        : city.isNotEmpty
            ? city
            : country.isNotEmpty
                ? country
                : 'Unknown location';

    final durationDays = widget.trip['duration_days'];
    final duration = durationDays != null ? '$durationDays days' : null;

    final price = widget.trip['price'];
    final currency = widget.trip['currency'] ?? 'EUR';
    final priceStr = price != null ? '${currency == 'EUR' ? '€' : '\$'}$price' : null;

    final rating = widget.trip['rating'];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                              Colors.black.withValues(alpha: 0.6),
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
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Delete button (top left)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF2A2A2A),
                            title: const Text(
                              'Delete Trip?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this trip?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onDelete();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // Favorite button (top right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: widget.onToggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          (widget.trip['is_favorite'] ?? false)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: (widget.trip['is_favorite'] ?? false)
                              ? Colors.red
                              : Colors.white,
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (duration != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (priceStr != null)
                      Expanded(
                        child: Text(
                          priceStr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
