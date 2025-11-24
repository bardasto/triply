import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isGridView = false;
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
        bottom: false,
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
              sliver: _isGridView
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.56,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final trip = _trips[index];
                          return _CompactTripCard(
                            trip: trip,
                            onDelete: () => _deleteTrip(trip['id']),
                            onToggleFavorite: () => _toggleFavorite(
                              trip['id'],
                              trip['is_favorite'] ?? false,
                            ),
                          );
                        },
                        childCount: _trips.length,
                      ),
                    )
                  : SliverList(
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
          _ViewToggleButton(
            isGridView: _isGridView,
            onToggle: (isGrid) {
              HapticFeedback.lightImpact();
              setState(() => _isGridView = isGrid);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppColors.darkBackground,
      child: SafeArea(
        bottom: false,
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
    const int maxImages = 4; // Максимум 4 фото в карточке

    // 1. Hero image first
    final heroImage = widget.trip['hero_image_url'];
    if (heroImage != null && heroImage.toString().isNotEmpty) {
      images.add(heroImage.toString());
    }

    // 2. Get LIMITED images from trip.images array (максимум 2-3 фото)
    if (images.length < maxImages) {
      final tripImages = widget.trip['images'];
      if (tripImages != null && tripImages is List) {
        int count = 0;
        for (var img in tripImages) {
          if (count >= 2) break; // Берем только 2 фото из trip.images
          final url = img is String ? img : img['url']?.toString();
          if (url != null && url.isNotEmpty && !images.contains(url)) {
            images.add(url);
            count++;
            if (images.length >= maxImages) break;
          }
        }
      }
    }

    // 3. Extract from itinerary places (только ПЕРВОЕ фото с каждого места)
    if (images.length < maxImages) {
      final itinerary = widget.trip['itinerary'];
      if (itinerary != null && itinerary is List) {
        for (var day in itinerary) {
          if (images.length >= maxImages) break;

          final places = day['places'];
          if (places != null && places is List) {
            for (var place in places) {
              if (images.length >= maxImages) break;

              // Берем только ПЕРВОЕ изображение с места
              final placeImages = place['images'];
              if (placeImages != null && placeImages is List && placeImages.isNotEmpty) {
                final imageUrl = placeImages[0] is String
                    ? placeImages[0]
                    : placeImages[0]['url']?.toString();
                if (imageUrl != null &&
                    imageUrl.isNotEmpty &&
                    !images.contains(imageUrl)) {
                  images.add(imageUrl);
                  break; // Берем только 1 фото с места и переходим к следующему месту
                }
              }

              // Fallback to image_url (только если не взяли из images)
              if (images.length < maxImages) {
                final imageUrl = place['image_url'];
                if (imageUrl != null &&
                    imageUrl.toString().isNotEmpty &&
                    !images.contains(imageUrl.toString())) {
                  images.add(imageUrl.toString());
                  break; // Берем только 1 фото с места
                }
              }
            }
          }
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
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

class _CompactTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _CompactTripCard({
    required this.trip,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  void _onTripTap(BuildContext context) {
    TripDetailsBottomSheet.show(
      context,
      trip: trip,
      isDarkMode: true,
    );
  }

  String? _getFirstImage() {
    // 1. Hero image first
    final heroImage = trip['hero_image_url'];
    if (heroImage != null && heroImage.toString().isNotEmpty) {
      return heroImage.toString();
    }

    // 2. First image from trip.images
    final tripImages = trip['images'];
    if (tripImages != null && tripImages is List && tripImages.isNotEmpty) {
      final img = tripImages[0];
      final url = img is String ? img : img['url']?.toString();
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    // 3. First image from itinerary
    final itinerary = trip['itinerary'];
    if (itinerary != null && itinerary is List) {
      for (var day in itinerary) {
        final places = day['places'];
        if (places != null && places is List) {
          for (var place in places) {
            final placeImages = place['images'];
            if (placeImages != null && placeImages is List && placeImages.isNotEmpty) {
              final imageUrl = placeImages[0] is String
                  ? placeImages[0]
                  : placeImages[0]['url']?.toString();
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return imageUrl;
              }
            }
            final imageUrl = place['image_url'];
            if (imageUrl != null && imageUrl.toString().isNotEmpty) {
              return imageUrl.toString();
            }
          }
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _getFirstImage();
    final title = trip['title'] ?? trip['name'] ?? 'Untitled Trip';
    final city = trip['city'] ?? '';
    final country = trip['country'] ?? '';
    final location = city.isNotEmpty && country.isNotEmpty
        ? '$city, $country'
        : city.isNotEmpty
            ? city
            : country.isNotEmpty
                ? country
                : 'Unknown location';

    final durationDays = trip['duration_days'];
    final duration = durationDays != null ? '$durationDays days' : null;

    final price = trip['price'];
    final currency = trip['currency'] ?? 'EUR';
    final priceStr = price != null ? '${currency == 'EUR' ? '€' : '\$'}$price' : null;

    final rating = trip['rating'];

    return GestureDetector(
      onTap: () => _onTripTap(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section - square
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                    if (image != null)
                      Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),

                    // Favorite button (top right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            (trip['is_favorite'] ?? false)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: (trip['is_favorite'] ?? false)
                                ? Colors.red
                                : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Trip info
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            location,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (rating != null && rating > 0) ...[
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (duration != null) ...[
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 2),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
          if (priceStr != null) ...[
            const SizedBox(height: 2),
            Text(
              priceStr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewToggleButton extends StatefulWidget {
  final bool isGridView;
  final ValueChanged<bool> onToggle;

  const _ViewToggleButton({
    required this.isGridView,
    required this.onToggle,
  });

  @override
  State<_ViewToggleButton> createState() => _ViewToggleButtonState();
}

class _ViewToggleButtonState extends State<_ViewToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _tappedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    setState(() => _tappedIndex = index);
    _controller.forward();
  }

  void _onTapUp(int index) {
    _controller.reverse().then((_) {
      setState(() => _tappedIndex = null);
    });
    widget.onToggle(index == 1);
  }

  void _onTapCancel() {
    _controller.reverse();
    setState(() => _tappedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(0, Icons.view_agenda_outlined, !widget.isGridView),
          const SizedBox(width: 4),
          _buildToggleItem(1, Icons.grid_view_rounded, widget.isGridView),
        ],
      ),
    );
  }

  Widget _buildToggleItem(int index, IconData icon, bool isActive) {
    final isTapped = _tappedIndex == index;

    return GestureDetector(
      onTapDown: (_) => _onTapDown(index),
      onTapUp: (_) => _onTapUp(index),
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          final scale = isTapped ? _scaleAnimation.value : 1.0;
          return Transform.scale(
            scale: scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}
