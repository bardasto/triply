import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/data/repositories/restaurant_repository.dart';
import 'fullscreen_restaurants_map.dart';
import 'trip_details/trip_details_image_gallery.dart';
import 'trip_details/trip_details_header.dart';
import 'trip_details/trip_details_sections.dart';
import 'trip_details/trip_details_dialogs.dart';
import 'trip_details/trip_details_utils.dart';
import 'trip_details/trip_details_day_card.dart';
import 'trip_details/trip_details_restaurant_card.dart';

class TripDetailsBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> trip,
    required bool isDarkMode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TripDetailsContent(
        trip: trip,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class _TripDetailsContent extends StatefulWidget {
  final Map<String, dynamic> trip;
  final bool isDarkMode;

  const _TripDetailsContent({
    required this.trip,
    required this.isDarkMode,
  });

  @override
  State<_TripDetailsContent> createState() => _TripDetailsContentState();
}

class _TripDetailsContentState extends State<_TripDetailsContent>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late TabController _tabController;
  int _currentImageIndex = 0;
  final Map<int, bool> _expandedDays = {};

  // Состояние для раскрытия описания
  bool _isDescriptionExpanded = false;

  final Set<String> _selectedPlaceIds = {};
  List<String> _filteredImages = [];

  final RestaurantRepository _restaurantRepository = RestaurantRepository();
  List<Map<String, dynamic>> _databaseRestaurants = [];
  bool _loadingRestaurants = false;

  // Флаг для предотвращения множественного вызова pop и краша
  bool _isClosing = false;

  bool get _isDark => widget.isDarkMode;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.text;
  Color get _textSecondary =>
      _isDark ? Colors.white70 : AppColors.textSecondary;
  Color get _dividerColor => _isDark ? Colors.white12 : Colors.grey[200]!;

  List<String> get _images {
    if (_selectedPlaceIds.isNotEmpty) {
      return _filteredImages;
    }
    return TripDetailsUtils.extractImagesFromTrip(widget.trip);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadRestaurantsFromDatabase();
  }

  Future<void> _loadRestaurantsFromDatabase() async {
    final city = widget.trip['city'] as String?;
    if (city == null || city.isEmpty) return;

    setState(() => _loadingRestaurants = true);

    try {
      final restaurants =
          await _restaurantRepository.getRestaurantsAsPlaceMaps(city);
      if (mounted) {
        setState(() {
          _databaseRestaurants = restaurants;
          _loadingRestaurants = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRestaurants = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Booking functionality coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _togglePlaceSelection(String placeId) {
    setState(() {
      if (_selectedPlaceIds.contains(placeId)) {
        _selectedPlaceIds.remove(placeId);
      } else {
        _selectedPlaceIds.add(placeId);
      }
      _updateFilteredImages();
      if (_filteredImages.isNotEmpty) {
        _currentImageIndex = 0;
        _pageController.jumpToPage(0);
      }
    });
  }

  void _updateFilteredImages() {
    _filteredImages.clear();
    if (_selectedPlaceIds.isEmpty) return;
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) return;
    for (var day in itinerary) {
      final places = day['places'] as List?;
      if (places == null) continue;
      for (var place in places) {
        final placeId = place['poi_id']?.toString() ?? place['name'];
        if (_selectedPlaceIds.contains(placeId)) {
          final imageUrl = TripDetailsUtils.getImageUrl(place);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            _filteredImages.add(imageUrl);
          }
        }
      }
    }
    if (_filteredImages.isEmpty && widget.trip['hero_image_url'] != null) {
      _filteredImages.add(widget.trip['hero_image_url'] as String);
    }
  }

  Future<void> _deletePlace(Map<String, dynamic> place) async {
    final confirm = await TripDetailsDialogs.showDeleteConfirmation(
      context,
      place: place,
      isDark: _isDark,
    );

    if (!confirm) return;

    setState(() {
      final itinerary = widget.trip['itinerary'] as List?;
      if (itinerary != null) {
        for (var day in itinerary) {
          final places = day['places'] as List?;
          if (places != null) {
            places.removeWhere((p) =>
                (p['poi_id']?.toString() ?? p['name']) ==
                (place['poi_id']?.toString() ?? place['name']));
          }
        }
      }
      final placeId = place['poi_id']?.toString() ?? place['name'];
      _selectedPlaceIds.remove(placeId);
      _updateFilteredImages();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${place['name']} removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _editPlace(Map<String, dynamic> place) {
    TripDetailsDialogs.showEditPlaceDialog(
      context,
      place: place,
      isDark: _isDark,
      onSave: (name, duration) {
        setState(() {
          place['name'] = name;
          if (duration != null) {
            place['duration_minutes'] = duration;
          }
        });
      },
    );
  }

  void _addPlaceToDay(Map<String, dynamic> day) {
    TripDetailsDialogs.showAddPlaceDialog(
      context,
      isDark: _isDark,
      onAdd: (name, category, duration) {
        setState(() {
          final places = day['places'] as List? ?? [];
          places.add({
            'name': name,
            'category': category,
            if (duration != null) 'duration_minutes': duration,
          });
          day['places'] = places;
        });
      },
    );
  }

  Future<void> _deleteRestaurant(Map<String, dynamic> restaurant) async {
    final confirm = await TripDetailsDialogs.showDeleteRestaurantConfirmation(
      context,
      restaurant: restaurant,
      isDark: _isDark,
    );

    if (!confirm) return;

    setState(() {
      final restaurantId =
          restaurant['poi_id']?.toString() ?? restaurant['name'];
      final itinerary = widget.trip['itinerary'] as List?;
      if (itinerary != null) {
        for (var day in itinerary) {
          final dayRestaurants = day['restaurants'] as List?;
          if (dayRestaurants != null) {
            dayRestaurants.removeWhere(
                (r) => (r['poi_id']?.toString() ?? r['name']) == restaurantId);
          }
          final places = day['places'] as List?;
          if (places != null) {
            places.removeWhere(
                (p) => (p['poi_id']?.toString() ?? p['name']) == restaurantId);
          }
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${restaurant['name']} removed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _replaceRestaurantWithMap(Map<String, dynamic> restaurant) async {
    final restaurantId = restaurant['poi_id']?.toString() ?? restaurant['name'];
    final allAvailableRestaurants = _getAllAvailableRestaurants();
    final restaurantsInTrip = _getRestaurantsInTrip();
    final tripRestaurantIds = restaurantsInTrip
        .map((r) => r['poi_id']?.toString() ?? r['name'])
        .toSet();

    final filteredRestaurants = allAvailableRestaurants.where((r) {
      final id = r['poi_id']?.toString() ?? r['name'];
      return !tripRestaurantIds.contains(id) || id == restaurantId;
    }).where((r) {
      final id = r['poi_id']?.toString() ?? r['name'];
      return id != restaurantId;
    }).toList();

    final selectedRestaurant =
        await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => FullscreenRestaurantsMap(
          restaurants: filteredRestaurants,
          isDark: _isDark,
          tripCity: widget.trip['city'] as String?,
          editingRestaurantId: restaurantId,
          onRestaurantSelected: (newRestaurant) {
            Navigator.of(context).pop(newRestaurant);
          },
        ),
      ),
    );

    if (selectedRestaurant != null && mounted) {
      setState(() {
        _replaceRestaurant(restaurant, selectedRestaurant);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedRestaurant['name']} replaced ${restaurant['name']}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _replaceRestaurant(
    Map<String, dynamic> oldRestaurant,
    Map<String, dynamic> newRestaurant,
  ) {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) return;

    final oldId = oldRestaurant['poi_id']?.toString() ?? oldRestaurant['name'];

    for (var day in itinerary) {
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        final index = dayRestaurants
            .indexWhere((r) => (r['poi_id']?.toString() ?? r['name']) == oldId);
        if (index != -1) {
          dayRestaurants[index] = newRestaurant;
          return;
        }
      }

      final places = day['places'] as List?;
      if (places != null) {
        final index = places
            .indexWhere((p) => (p['poi_id']?.toString() ?? p['name']) == oldId);
        if (index != -1) {
          places[index] = newRestaurant;
          return;
        }
      }
    }
  }

  List<Map<String, dynamic>> _getAllAvailableRestaurants() {
    if (_databaseRestaurants.isNotEmpty) {
      return _databaseRestaurants;
    }

    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) return [];

    final allRestaurants = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var day in itinerary) {
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        for (var restaurant in dayRestaurants) {
          final id = restaurant['poi_id']?.toString() ?? restaurant['name'];
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            allRestaurants.add(restaurant as Map<String, dynamic>);
          }
        }
      }

      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category == 'breakfast' ||
              category == 'lunch' ||
              category == 'dinner') {
            final id = place['poi_id']?.toString() ?? place['name'];
            if (!seenIds.contains(id)) {
              seenIds.add(id);
              allRestaurants.add(place as Map<String, dynamic>);
            }
          }
        }
      }
    }

    return allRestaurants;
  }

  List<Map<String, dynamic>> _getRestaurantsInTrip() {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) return [];

    final restaurants = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var day in itinerary) {
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        for (var restaurant in dayRestaurants) {
          final id = restaurant['poi_id']?.toString() ?? restaurant['name'];
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            restaurants.add(restaurant as Map<String, dynamic>);
          }
        }
      }

      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category == 'breakfast' ||
              category == 'lunch' ||
              category == 'dinner') {
            final id = place['poi_id']?.toString() ?? place['name'];
            if (!seenIds.contains(id)) {
              seenIds.add(id);
              restaurants.add(place as Map<String, dynamic>);
            }
          }
        }
      }
    }

    return restaurants;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= 0.05 && !_isClosing) {
          _isClosing = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
        }
        return false;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.85,
        minChildSize: 0.0,
        expand: false,
        snap: true,
        snapSizes: const [0.85],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: CustomScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 30)),
                        SliverToBoxAdapter(
                          child: TripDetailsImageGallery(
                            images: _images,
                            currentImageIndex: _currentImageIndex,
                            pageController: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            isDark: _isDark,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildContentSections(),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildStaticHeader(),
                _buildCloseButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 30,
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Container(
          width: 60,
          height: 3,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color:
                (_isDark ? Colors.white : Colors.grey).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 12,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              color: _isDark ? Colors.white : AppColors.text,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        TripDetailsHeader(trip: widget.trip, isDark: _isDark),
        Divider(height: 1, color: _dividerColor),
        // Используем наш новый метод вместо TripDetailsSections.buildAboutSection
        _buildDescriptionSection(),
        Divider(height: 1, color: _dividerColor),
        if (widget.trip['includes'] != null &&
            (widget.trip['includes'] as List).isNotEmpty) ...[
          TripDetailsSections.buildIncludesSection(
              trip: widget.trip, isDark: _isDark),
          Divider(height: 1, color: _dividerColor),
        ],
        _buildItinerarySection(),
        const SizedBox(height: 20),
        TripDetailsSections.buildBookButton(
          onBook: _handleBooking,
          isDark: _isDark,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // Новый метод для отображения описания с функцией See more
  Widget _buildDescriptionSection() {
    final description = widget.trip['description'] as String? ?? '';
    if (description.isEmpty) return const SizedBox.shrink();

    // Количество символов для обрезки
    const int trimLength = 200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this trip',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          // Если текст короткий, просто выводим его
          if (description.length <= trimLength)
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: _textSecondary,
              ),
            )
          else
            // Используем RichText для добавления кликабельной части "See more"
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: _textSecondary,
                ),
                children: [
                  TextSpan(
                    text: _isDescriptionExpanded
                        ? description
                        : '${description.substring(0, trimLength)}...',
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

  Widget _buildItinerarySection() {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null || itinerary.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Itinerary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detailed itinerary coming soon',
                      style: TextStyle(fontSize: 14, color: _textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedPlaceIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedPlaceIds.clear();
                        _filteredImages.clear();
                        _currentImageIndex = 0;
                      });
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear filter'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: _isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: _textSecondary,
              indicator: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
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

          if (filteredPlaces.isEmpty) {
            return const SizedBox.shrink();
          }

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
        for (var restaurant in dayRestaurants) {
          restaurants.add(restaurant as Map<String, dynamic>);
        }
      }

      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category == 'breakfast' ||
              category == 'lunch' ||
              category == 'dinner') {
            restaurants.add(place as Map<String, dynamic>);
          }
        }
      }
    }

    if (restaurants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: _textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No restaurants added yet',
                style: TextStyle(fontSize: 14, color: _textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final previewRestaurants = restaurants.take(4).toList();
    final allAvailableRestaurants = _getAllAvailableRestaurants();
    final restaurantsInTrip = _getRestaurantsInTrip();
    final tripRestaurantIdentifiers = <String>{};

    for (var r in restaurantsInTrip) {
      if (r['poi_id'] != null) {
        tripRestaurantIdentifiers.add(r['poi_id'].toString());
      }
      if (r['google_place_id'] != null) {
        tripRestaurantIdentifiers.add(r['google_place_id'].toString());
      }
      if (r['name'] != null) {
        tripRestaurantIdentifiers.add(r['name'].toString().toLowerCase());
      }
    }

    final availableRestaurants = allAvailableRestaurants.where((r) {
      final poiId = r['poi_id']?.toString();
      final googlePlaceId = r['google_place_id']?.toString();
      final name = r['name']?.toString().toLowerCase();

      final isInTrip =
          (poiId != null && tripRestaurantIdentifiers.contains(poiId)) ||
              (googlePlaceId != null &&
                  tripRestaurantIdentifiers.contains(googlePlaceId)) ||
              (name != null && tripRestaurantIdentifiers.contains(name));

      return !isInTrip;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...previewRestaurants.map((restaurant) => TripDetailsRestaurantCard(
              restaurant: restaurant,
              trip: widget.trip,
              isDark: _isDark,
              onReplace: () => _replaceRestaurantWithMap(restaurant),
              onDelete: () => _deleteRestaurant(restaurant),
            )),
        const SizedBox(height: 8),
        _buildViewAllRestaurantsButton(availableRestaurants),
      ],
    );
  }

  Widget _buildViewAllRestaurantsButton(
      List<Map<String, dynamic>> availableRestaurants) {
    return InkWell(
      onTap: () async {
        final selectedRestaurant =
            await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (_) => FullscreenRestaurantsMap(
              restaurants: availableRestaurants,
              isDark: _isDark,
              tripCity: widget.trip['city'] as String?,
              onRestaurantSelected: (newRestaurant) {
                Navigator.of(context).pop(newRestaurant);
              },
            ),
          ),
        );

        if (selectedRestaurant != null && mounted) {
          setState(() {
            _addNewRestaurant(selectedRestaurant);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selectedRestaurant['name']} added to trip'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'View All Restaurants on Map',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewRestaurant(Map<String, dynamic> restaurant) {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null || itinerary.isEmpty) return;

    final firstDay = itinerary[0] as Map<String, dynamic>;
    final places = firstDay['places'] as List? ?? [];
    places.add(restaurant);
    firstDay['places'] = places;
  }

  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final dayNumber = day['day'] ?? (index + 1);
    final isExpanded = _expandedDays[dayNumber] ?? false;

    return TripDetailsDayCard(
      day: day,
      index: index,
      isExpanded: isExpanded,
      isDark: _isDark,
      trip: widget.trip,
      selectedPlaceIds: _selectedPlaceIds,
      onToggleExpand: () {
        setState(() {
          _expandedDays[dayNumber] = !isExpanded;
        });
      },
      onAddPlace: () => _addPlaceToDay(day),
      onEditPlace: _editPlace,
      onDeletePlace: _deletePlace,
      onToggleSelection: _togglePlaceSelection,
      onPlaceLongPress: (place) {
        // Long press functionality can be added here if needed
      },
    );
  }
}
