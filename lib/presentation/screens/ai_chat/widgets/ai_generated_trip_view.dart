import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/color_constants.dart';
import '../../home/widgets/trip_details/trip_details_sections.dart';
import '../../home/widgets/trip_details/trip_details_day_card.dart';

class AiGeneratedTripView extends StatefulWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onBack;

  const AiGeneratedTripView({
    super.key,
    required this.trip,
    required this.onBack,
  });

  @override
  State<AiGeneratedTripView> createState() => _AiGeneratedTripViewState();
}

class _AiGeneratedTripViewState extends State<AiGeneratedTripView>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  final Map<int, bool> _expandedDays = {};
  final Set<String> _selectedPlaceIds = {};
  late PageController _photoPageController;

  double _scrollOpacity = 0.0;
  double _headerOpacity = 0.0;
  int _currentPhotoIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _photoPageController = PageController();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newOpacity = (offset / 200).clamp(0.0, 1.0);
    final newHeaderOpacity = (offset / 100).clamp(0.0, 1.0);

    if ((_scrollOpacity - newOpacity).abs() > 0.01) {
      setState(() {
        _scrollOpacity = newOpacity;
        _headerOpacity = newHeaderOpacity;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _photoPageController.dispose();
    super.dispose();
  }

  List<String> get _allPlaceImages {
    final List<String> allImages = [];
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary != null) {
      for (final day in itinerary) {
        final places = day['places'] as List?;
        if (places != null) {
          for (final place in places) {
            final placeImages = place['images'] as List?;
            if (placeImages != null && placeImages.isNotEmpty) {
              int photosAdded = 0;
              for (final img in placeImages) {
                if (photosAdded >= 2) break;
                String? url;
                if (img is String) {
                  url = img;
                } else if (img is Map && img['url'] != null) {
                  url = img['url'].toString();
                }
                if (url != null && url.isNotEmpty) {
                  allImages.add(url);
                  photosAdded++;
                }
              }
            } else {
              final imageUrl = place['image_url'] as String?;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                allImages.add(imageUrl);
              }
            }
          }
        }
      }
    }
    if (allImages.isEmpty) {
      final heroImageUrl = widget.trip['hero_image_url'] as String?;
      if (heroImageUrl != null && heroImageUrl.isNotEmpty) {
        allImages.add(heroImageUrl);
      }
    }
    return allImages.isNotEmpty
        ? allImages
        : ['https://via.placeholder.com/800x600?text=Trip+Image'];
  }

  String get _tripTitle {
    final title = widget.trip['title'] as String?;
    final name = widget.trip['name'] as String?;
    final city = widget.trip['city'] as String?;
    return title ?? name ?? (city != null ? 'Trip to $city' : 'Untitled Trip');
  }

  // --- МЕТОДЫ ДЛЯ ПЕРЕКЛЮЧЕНИЯ ФОТО ---
  void _nextImage() {
    final images = _allPlaceImages;
    if (_currentPhotoIndex < images.length - 1) {
      _photoPageController.animateToPage(
        _currentPhotoIndex + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevImage() {
    if (_currentPhotoIndex > 0) {
      _photoPageController.animateToPage(
        _currentPhotoIndex - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  // Обработка тапа, переданная внутрь зумируемого виджета
  void _handleTap(TapUpDetails details, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (details.localPosition.dx < width / 2) {
      _prevImage();
    } else {
      _nextImage();
    }
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero Image & Title Section
                SliverToBoxAdapter(
                  child: _buildHeroSection(),
                ),

                // Trip content
                SliverToBoxAdapter(
                  child: _buildTripContent(),
                ),
              ],
            ),

            // Floating header with back button
            _buildFloatingHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final images = _allPlaceImages;
    final price = widget.trip['price'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Галерея с закруглением, зумом и навигацией
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: SizedBox(
            height: 350,
            child: Stack(
              children: [
                // Свайпаемая галерея с поддержкой зума
                PageView.builder(
                  controller: _photoPageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    // Используем кастомный виджет для зума
                    return _ZoomableImage(
                      imageUrl: images[index],
                      // Передаем обработку тапа внутрь, так как InteractiveViewer перехватывает жесты
                      onTapUp: (details) => _handleTap(details, context),
                    );
                  },
                ),

                // Градиент снизу
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    // IgnorePointer чтобы градиент не мешал жестам
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Индикаторы-полоски (Telegram Style)
                if (images.length > 1)
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Row(
                      children: List.generate(images.length, (idx) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 3,
                              decoration: BoxDecoration(
                                color: idx == _currentPhotoIndex
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
              ],
            ),
          ),
        ),

        // 2. Заголовок, Город и Цена
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tripTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.trip['city'] ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (price != null) ...[
                const SizedBox(height: 12),
                Text(
                  'from \$$price',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.darkBackground.withValues(alpha: _scrollOpacity),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withValues(alpha: 0.3 + (_scrollOpacity * 0.4)),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (_headerOpacity > 0.5) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Opacity(
                      opacity: _headerOpacity,
                      child: Text(
                        _tripTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripContent() {
    final dividerColor = Colors.white.withValues(alpha: 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTripStats(),
        Divider(height: 1, color: dividerColor),
        _buildAboutSection(),
        Divider(height: 1, color: dividerColor),
        if (widget.trip['includes'] != null &&
            (widget.trip['includes'] as List).isNotEmpty) ...[
          TripDetailsSections.buildIncludesSection(
            trip: widget.trip,
            isDark: true,
          ),
          Divider(height: 1, color: dividerColor),
        ],
        _buildItinerarySection(),
        const SizedBox(height: 20),
        TripDetailsSections.buildBookButton(
          onBook: _handleBooking,
          isDark: true,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTripStats() {
    final duration = widget.trip['duration']?.toString() ??
        widget.trip['days']?.toString() ??
        '7';
    final rating = widget.trip['rating']?.toString() ?? '4.5';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.access_time,
              color: Colors.white.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 6),
          Text(
            '$duration days',
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 24),
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Text(
            rating,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarySection() {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null || itinerary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.white70,
              indicator: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Places'),
                Tab(text: 'Restaurants'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_tabController.index == 0)
            _buildPlacesTab(itinerary)
          else
            _buildRestaurantsTab(itinerary),
        ],
      ),
    );
  }

  Widget _buildPlacesTab(List<dynamic> itinerary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: itinerary.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value as Map<String, dynamic>;
        final allPlaces = day['places'] as List?;
        if (allPlaces != null) {
          final filteredPlaces = allPlaces.where((place) {
            final category = place['category'] as String?;
            return category != 'breakfast' &&
                category != 'lunch' &&
                category != 'dinner';
          }).toList();
          if (filteredPlaces.isEmpty) return const SizedBox.shrink();
          final filteredDay = Map<String, dynamic>.from(day);
          filteredDay['places'] = filteredPlaces;
          return _buildDayCard(filteredDay, index);
        }
        return _buildDayCard(day, index);
      }).toList(),
    );
  }

  Widget _buildRestaurantsTab(List<dynamic> itinerary) {
    final List<Map<String, dynamic>> restaurants = [];
    for (var day in itinerary) {
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        for (var r in dayRestaurants)
          restaurants.add(r as Map<String, dynamic>);
      }
      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final cat = place['category'] as String?;
          if (cat == 'breakfast' || cat == 'lunch' || cat == 'dinner') {
            restaurants.add(place as Map<String, dynamic>);
          }
        }
      }
    }

    if (restaurants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No restaurants added yet',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
      );
    }

    return Column(
      children: restaurants.map((restaurant) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.restaurant, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  restaurant['name'] ?? 'Restaurant',
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final dayNumber = day['day'] ?? (index + 1);
    final isExpanded = _expandedDays[dayNumber] ?? false;

    return TripDetailsDayCard(
      day: day,
      index: index,
      isExpanded: isExpanded,
      isDark: true,
      trip: widget.trip,
      selectedPlaceIds: _selectedPlaceIds,
      onToggleExpand: () {
        setState(() {
          _expandedDays[dayNumber] = !isExpanded;
        });
      },
      onAddPlace: () {},
      onEditPlace: (place) {},
      onDeletePlace: (place) {},
      onToggleSelection: (placeId) {},
      onPlaceLongPress: (place) {},
    );
  }

  Widget _buildAboutSection() {
    final description =
        widget.trip['description'] as String? ?? 'No description available.';
    const int maxLength = 150;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (description.length <= maxLength)
            Text(
              description,
              style: const TextStyle(
                  fontSize: 15, height: 1.5, color: Colors.white70),
            )
          else
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 15, height: 1.5, color: Colors.white70),
                children: [
                  TextSpan(
                    text: _isDescriptionExpanded
                        ? description
                        : '${description.substring(0, maxLength)}...',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _isDescriptionExpanded ? 'See less' : 'See more',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Booking functionality coming soon!')),
    );
  }
}

// --- ВИДЖЕТ ДЛЯ ЗУМА "КАК В TELEGRAM" ---
class _ZoomableImage extends StatefulWidget {
  final String imageUrl;
  final Function(TapUpDetails) onTapUp;

  const _ZoomableImage({
    required this.imageUrl,
    required this.onTapUp,
  });

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  late TransformationController _controller;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        _controller.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Возврат к масштабу 1.0 при отпускании пальцев
  void _resetAnimation() {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Обрабатываем тапы для переключения фото
      onTapUp: widget.onTapUp,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1.0,
        maxScale: 4.0,
        // Позволяем свайпать PageView, если не зумим
        panEnabled: false,
        // Возвращаем фото в исходное состояние при окончании жеста
        onInteractionEnd: (details) {
          _resetAnimation();
        },
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[900],
            child: const Icon(Icons.image_not_supported, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
