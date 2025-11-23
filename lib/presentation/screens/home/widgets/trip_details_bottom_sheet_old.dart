import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/data/repositories/restaurant_repository.dart';
import 'place_details_screen.dart';
import '../../restaurants_map/fullscreen_restaurants_map.dart';



class TripDetailsBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> trip,
    required bool isDarkMode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
  final PageController _pageController = PageController(); // Full width photos
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  int _currentImageIndex = 0;
  final Map<int, bool> _expandedDays = {};

  final Set<String> _selectedPlaceIds = {};
  List<String> _filteredImages = [];

  // ✅ NEW: Restaurant database integration
  final RestaurantRepository _restaurantRepository = RestaurantRepository();
  List<Map<String, dynamic>> _databaseRestaurants = [];
  bool _loadingRestaurants = false;

  bool get _isDark => widget.isDarkMode;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.text;
  Color get _textSecondary =>
      _isDark ? Colors.white70 : AppColors.textSecondary;
  Color get _dividerColor => _isDark ? Colors.white12 : Colors.grey[200]!;


  // ✅ НОВЫЙ: Показываем только hero + 1 фото на место
  List<String> get _images {
    // Если выбраны конкретные места - показываем их фильтрованные фото
    if (_selectedPlaceIds.isNotEmpty) {
      return _filteredImages;
    }

    // ✅ Собираем hero + по 1 фото на место
    final List<String> result = [];

    // 1. Hero image (если есть)
    final heroUrl = widget.trip['hero_image_url'];
    if (heroUrl != null && heroUrl is String && heroUrl.isNotEmpty) {
      result.add(heroUrl);
    }

    // 2. По ОДНОЙ фотографии для каждого места в itinerary
    final itinerary = widget.trip['itinerary'];
    if (itinerary != null && itinerary is List) {
      for (var day in itinerary) {
        if (day is! Map) continue;

        final places = day['places'];
        if (places != null && places is List) {
          for (var place in places) {
            if (place is! Map) continue;

            // ✅ Берем ПЕРВОЕ фото из images[] (новая структура)
            String? imageUrl;

            // Пробуем взять из массива images[]
            if (place['images'] != null && place['images'] is List) {
              final images = place['images'] as List;
              if (images.isNotEmpty && images[0] is Map) {
                imageUrl = (images[0] as Map)['url']?.toString();
              }
            }

            // Fallback: используем image_url (старая структура)
            if (imageUrl == null || imageUrl.isEmpty) {
              imageUrl = place['image_url']?.toString();
            }

            if (imageUrl != null && imageUrl.isNotEmpty) {
              // ✅ Избегаем дубликатов
              if (!result.contains(imageUrl)) {
                result.add(imageUrl);
              }
            }
          }
        }
      }
    }

    // 3. Fallback: если совсем нет фото
    if (result.isEmpty) {
      final fallbackUrl = widget.trip['image_url'] ??
          'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800';
      result.add(fallbackUrl as String);
    }

    return result;
  }


  String get _formattedPrice {
    final price = widget.trip['price']?.toString() ?? '\$999';
    return price.replaceFirst('from ', '').replaceFirst('From ', '');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadRestaurantsFromDatabase(); // ✅ NEW: Load restaurants from database
  }

  // ✅ NEW: Load restaurants from database
  Future<void> _loadRestaurantsFromDatabase() async {
    final city = widget.trip['city'] as String?;
    debugPrint('🍽️  Loading restaurants from database for city: $city');

    if (city == null || city.isEmpty) {
      debugPrint('   ❌ City is null or empty, skipping restaurant load');
      return;
    }

    setState(() => _loadingRestaurants = true);

    try {
      final restaurants = await _restaurantRepository.getRestaurantsAsPlaceMaps(city);
      debugPrint('   ✅ Loaded ${restaurants.length} restaurants from database');

      if (restaurants.isNotEmpty) {
        debugPrint('   📋 First restaurant: ${restaurants[0]['name']}');
      }

      if (mounted) {
        setState(() {
          _databaseRestaurants = restaurants;
          _loadingRestaurants = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading restaurants: $e');
      if (mounted) {
        setState(() => _loadingRestaurants = false);
      }
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
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


  void _togglePlaceSelection(Map<String, dynamic> place) {
    setState(() {
      final placeId = place['poi_id']?.toString() ?? place['name'];
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
          // ✅ Берем ПЕРВОЕ фото из images[] (новая структура)
          String? imageUrl;

          // Пробуем взять из массива images[]
          if (place['images'] != null && place['images'] is List) {
            final images = place['images'] as List;
            if (images.isNotEmpty && images[0] is Map) {
              imageUrl = (images[0] as Map)['url']?.toString();
            }
          }

          // Fallback: используем image_url (старая структура)
          if (imageUrl == null || imageUrl.isEmpty) {
            imageUrl = place['image_url']?.toString();
          }

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


  // Показать диалог подтверждения удаления
  Future<bool> _showDeleteConfirmation(Map<String, dynamic> place) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _backgroundColor,
            title: Text('Delete Place?', style: TextStyle(color: _textPrimary)),
            content: Text(
              'Are you sure you want to remove "${place['name']}" from the itinerary?',
              style: TextStyle(color: _textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: TextStyle(color: _textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  _deletePlace(place);
                },
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Показать меню опций при долгом нажатии
  void _showPlaceOptionsMenu(Map<String, dynamic> place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  place['name'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: Text('Edit Place',
                    style: TextStyle(color: _textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _editPlace(place);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Place',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(place);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Удалить место из itinerary
  void _deletePlace(Map<String, dynamic> place) {
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
      // Убрать из выбранных, если было выбрано
      final placeId = place['poi_id']?.toString() ?? place['name'];
      _selectedPlaceIds.remove(placeId);
      _updateFilteredImages();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${place['name']} removed from itinerary'),
        backgroundColor: Colors.red.shade400,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  // Редактировать место
  void _editPlace(Map<String, dynamic> place) {
    final nameController = TextEditingController(text: place['name']);
    final durationController = TextEditingController(
        text: place['duration_minutes']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Edit Place', style: TextStyle(color: _textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: _textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _dividerColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                style: TextStyle(color: _textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  labelStyle: TextStyle(color: _textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _dividerColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                place['name'] = nameController.text;
                if (durationController.text.isNotEmpty) {
                  place['duration_minutes'] =
                      int.tryParse(durationController.text);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Place updated successfully'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // Добавить новое место в день
  void _addPlaceToDay(Map<String, dynamic> day) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        title: Text('Add New Place', style: TextStyle(color: _textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  labelText: 'Place Name',
                  labelStyle: TextStyle(color: _textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _dividerColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: _backgroundColor,
                style: TextStyle(color: _textPrimary),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: _textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _dividerColor),
                  ),
                ),
                items: ['attraction', 'breakfast', 'lunch', 'dinner']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  categoryController.text = value ?? 'attraction';
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                style: TextStyle(color: _textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  labelStyle: TextStyle(color: _textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _dividerColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a place name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setState(() {
                final places = day['places'] as List? ?? [];
                places.add({
                  'name': nameController.text,
                  'category': categoryController.text.isEmpty
                      ? 'attraction'
                      : categoryController.text,
                  'duration_minutes': durationController.text.isEmpty
                      ? null
                      : int.tryParse(durationController.text),
                  'poi_id': DateTime.now().millisecondsSinceEpoch.toString(),
                });
                day['places'] = places;
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${nameController.text} added successfully'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Add', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Padding for drag handle area
                SliverToBoxAdapter(
                  child: const SizedBox(height: 28),
                ),
                // Image gallery
                SliverToBoxAdapter(
                  child: _buildImageGallery(),
                ),
                // Scrollable content
                SliverToBoxAdapter(
                  child: _buildContentSections(),
                ),
              ],
            ),
          ),
          _buildDragHandle(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      children: [
        // Main photo with swipe
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.white, size: 50),
                          ),
                        ),
                      ),
                      // Photo counter
                      if (_images.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${_images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Horizontal thumbnail list
        if (_images.length > 1)
          Container(
            height: 80,
            margin: const EdgeInsets.only(top: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: EdgeInsets.only(
                      right: index < _images.length - 1 ? 8 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Opacity(
                      opacity: isSelected ? 1.0 : 0.5,
                      child: Image.network(
                        _images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.white, size: 30),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildContentSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildHeader(),
        Divider(height: 1, color: _dividerColor),
        _buildAboutSection(),
        Divider(height: 1, color: _dividerColor),
        if (widget.trip['includes'] != null &&
            (widget.trip['includes'] as List).isNotEmpty) ...[
          _buildIncludesSection(),
          Divider(height: 1, color: _dividerColor),
        ],
        _buildItinerarySection(),
        const SizedBox(height: 20),
        _buildBookButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.trip['title'] ?? 'Untitled Trip',
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: _textSecondary),
              const SizedBox(width: 4),
              Text(widget.trip['duration'] ?? '7 days',
                  style: TextStyle(fontSize: 14, color: _textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${widget.trip['rating'] ?? 0.0}',
                  style: TextStyle(fontSize: 14, color: _textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: 16,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500),
              children: [
                const TextSpan(text: 'from '),
                TextSpan(
                  text: _formattedPrice,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this trip',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary)),
          const SizedBox(height: 12),
          Text(
            widget.trip['description'] ?? 'No description available.',
            style: TextStyle(fontSize: 16, color: _textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludesSection() {
    final includes = widget.trip['includes'] as List;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's included",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary)),
          const SizedBox(height: 12),
          ...includes.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(item.toString(),
                          style: TextStyle(fontSize: 16, color: _textPrimary))),
                ],
              ),
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
            Text('Itinerary',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: _isDark ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Detailed itinerary coming soon',
                          style:
                              TextStyle(fontSize: 14, color: _textSecondary))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ TAB BAR VERSION
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with clear button
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

          // TabBar
          Container(
            decoration: BoxDecoration(
              color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
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

          // TabBarView - Dynamic height based on selected tab
          if (_tabController.index == 0)
            _buildPlacesTab(itinerary)
          else
            _buildRestaurantsTab(itinerary),
        ],
      ),
    );
  }

  // ✅ PLACES TAB - Only attractions, museums, etc (NO restaurants)
  Widget _buildPlacesTab(List<dynamic> itinerary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: itinerary.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value as Map<String, dynamic>;

        // Filter only non-restaurant places
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

          // Create a copy of day with filtered places
          final filteredDay = Map<String, dynamic>.from(day);
          filteredDay['places'] = filteredPlaces;
          return _buildDayCard(filteredDay, index);
        }

        return _buildDayCard(day, index);
      }).toList(),
    );
  }

  // ✅ RESTAURANTS TAB - Show preview list with "View All" button
  Widget _buildRestaurantsTab(List<dynamic> itinerary) {
    // Collect all restaurants from all days
    final List<Map<String, dynamic>> restaurants = [];

    for (var day in itinerary) {
      // ✅ NEW: Read from restaurants[] array first
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        for (var restaurant in dayRestaurants) {
          restaurants.add(restaurant as Map<String, dynamic>);
        }
      }

      // ✅ FALLBACK: For backward compatibility, also check places[] with restaurant categories
      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category == 'breakfast' || category == 'lunch' || category == 'dinner') {
            restaurants.add(place as Map<String, dynamic>);
          }
        }
      }
    }

    if (restaurants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
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

    // Show preview (max 4 restaurants)
    final previewRestaurants = restaurants.take(4).toList();

    // Calculate available restaurants (not in trip)
    final allAvailableRestaurants = _getAllAvailableRestaurants();
    final restaurantsInTrip = _getRestaurantsInTrip();

    // Create a set of identifiers for restaurants in trip (poi_id, google_place_id, and name)
    final tripRestaurantIdentifiers = <String>{};
    for (var r in restaurantsInTrip) {
      if (r['poi_id'] != null) tripRestaurantIdentifiers.add(r['poi_id'].toString());
      if (r['google_place_id'] != null) tripRestaurantIdentifiers.add(r['google_place_id'].toString());
      if (r['name'] != null) tripRestaurantIdentifiers.add(r['name'].toString().toLowerCase());
    }

    // Filter out restaurants that are already in the trip
    final availableRestaurants = allAvailableRestaurants.where((r) {
      // Check if restaurant is already in trip by poi_id, google_place_id, or name
      final poiId = r['poi_id']?.toString();
      final googlePlaceId = r['google_place_id']?.toString();
      final name = r['name']?.toString().toLowerCase();

      final isInTrip = (poiId != null && tripRestaurantIdentifiers.contains(poiId)) ||
                       (googlePlaceId != null && tripRestaurantIdentifiers.contains(googlePlaceId)) ||
                       (name != null && tripRestaurantIdentifiers.contains(name));

      return !isInTrip;
    }).toList();

    debugPrint('🍽️  Restaurant filtering:');
    debugPrint('   Total available: ${allAvailableRestaurants.length}');
    debugPrint('   In trip: ${restaurantsInTrip.length}');
    debugPrint('   After filter: ${availableRestaurants.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Restaurant preview cards
        ...previewRestaurants.map((restaurant) => _buildRestaurantPreviewCard(restaurant)),

        // "View All" button
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedRestaurant = await Navigator.of(context).push<Map<String, dynamic>>(
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

            // Add new restaurant if one was selected
            if (selectedRestaurant != null && mounted) {
              setState(() {
                _addNewRestaurant(selectedRestaurant);
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedRestaurant['name']} added to itinerary'),
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
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'View All (${availableRestaurants.length})',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build preview card for restaurant in the list
  Widget _buildRestaurantPreviewCard(Map<String, dynamic> restaurant) {
    // ✅ Support both image_url and images array
    String? imageUrl;

    // Try to get first image from images[] array (object format: {url, source, alt_text})
    if (restaurant['images'] != null && restaurant['images'] is List) {
      final images = restaurant['images'] as List;
      if (images.isNotEmpty && images[0] is Map) {
        imageUrl = (images[0] as Map)['url']?.toString();
      }
    }

    // Fallback to image_url
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = restaurant['image_url'] as String?;
    }

    final category = restaurant['category'] as String? ?? 'restaurant';
    final restaurantId = restaurant['poi_id']?.toString() ?? restaurant['name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        key: Key(restaurantId),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.45,
          children: [
            CustomSlidableAction(
              onPressed: (_) => _replaceRestaurantWithMap(restaurant),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_horiz, color: Colors.white, size: 24),
                  SizedBox(height: 6),
                  Text(
                    'Replace',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (context) async {
                final confirm = await _showDeleteRestaurantConfirmation(restaurant);
                if (!confirm && context.mounted) {
                  final slidableState = Slidable.of(context);
                  slidableState?.close();
                }
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 24),
                  SizedBox(height: 6),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlaceDetailsScreen(
                  place: restaurant,
                  trip: widget.trip,
                  isDark: _isDark,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDark ? Colors.white.withValues(alpha: 0.07) : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Image/Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _getCategoryIcon(category),
                        )
                      : _getCategoryIcon(category),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant['name'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getCategoryLabel(category),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(category),
                              ),
                            ),
                          ),
                          if (restaurant['rating'] != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              "${restaurant['rating']}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(Icons.chevron_right, color: _textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.deepPurple;
      default:
        return Colors.orange;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return 'Restaurant';
    }
  }

  // Replace restaurant - open fullscreen map with available restaurants
  void _replaceRestaurantWithMap(Map<String, dynamic> restaurant) async {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) return;

    final restaurantId = restaurant['poi_id']?.toString() ?? restaurant['name'];

    // Collect ALL available restaurants from the city
    // This would typically come from backend, but for now we use what's in itinerary
    final List<Map<String, dynamic>> allAvailableRestaurants = _getAllAvailableRestaurants();

    // Collect restaurants already in trip
    final restaurantsInTrip = _getRestaurantsInTrip();
    final tripRestaurantIds = restaurantsInTrip
        .map((r) => r['poi_id']?.toString() ?? r['name'])
        .toSet();

    // Filter: exclude restaurants in trip AND the one being replaced
    final filteredRestaurants = allAvailableRestaurants.where((r) {
      final id = r['poi_id']?.toString() ?? r['name'];
      // Keep only if: not in trip AND not the one being replaced
      return !tripRestaurantIds.contains(id) || id == restaurantId;
    }).where((r) {
      final id = r['poi_id']?.toString() ?? r['name'];
      return id != restaurantId; // Exclude the one being replaced
    }).toList();

    // Open map in replace mode
    final selectedRestaurant = await Navigator.of(context).push<Map<String, dynamic>>(
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

    // Replace restaurant if one was selected
    if (selectedRestaurant != null && mounted) {
      setState(() {
        _replaceRestaurant(restaurant, selectedRestaurant);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedRestaurant['name']} replaced ${restaurant['name']}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  // ✅ UPDATED: Get all available restaurants from database
  List<Map<String, dynamic>> _getAllAvailableRestaurants() {
    debugPrint('🔍 _getAllAvailableRestaurants called');
    debugPrint('   Database restaurants count: ${_databaseRestaurants.length}');

    // Return restaurants from database if loaded
    if (_databaseRestaurants.isNotEmpty) {
      debugPrint('   ✅ Returning ${_databaseRestaurants.length} restaurants from database');
      return _databaseRestaurants;
    }

    debugPrint('   ⚠️  No database restaurants, using fallback from itinerary');

    // Fallback: Get from itinerary (legacy)
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) {
      debugPrint('   ❌ No itinerary available');
      return [];
    }

    final allRestaurants = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var day in itinerary) {
      // ✅ NEW: Read from restaurants[] array first
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

      // ✅ FALLBACK: For backward compatibility, also check places[] with restaurant categories
      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category == 'breakfast' || category == 'lunch' || category == 'dinner') {
            final id = place['poi_id']?.toString() ?? place['name'];
            if (!seenIds.contains(id)) {
              seenIds.add(id);
              allRestaurants.add(place as Map<String, dynamic>);
            }
          }
        }
      }
    }

    debugPrint('   📊 Found ${allRestaurants.length} restaurants from itinerary');
    return allRestaurants;
  }

  // Get restaurants currently in trip
  List<Map<String, dynamic>> _getRestaurantsInTrip() {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) return [];

    final restaurants = <Map<String, dynamic>>[];
    for (var day in itinerary) {
      // ✅ NEW: Read from restaurants[] array first
      final dayRestaurants = day['restaurants'] as List?;
      if (dayRestaurants != null) {
        for (var restaurant in dayRestaurants) {
          restaurants.add(restaurant as Map<String, dynamic>);
        }
      }

      // ✅ FALLBACK: For backward compatibility, also check places[] with restaurant categories
      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category == 'breakfast' || category == 'lunch' || category == 'dinner') {
            restaurants.add(place as Map<String, dynamic>);
          }
        }
      }
    }

    return restaurants;
  }

  // Replace one restaurant with another in the itinerary
  void _replaceRestaurant(Map<String, dynamic> oldRestaurant, Map<String, dynamic> newRestaurant) {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null) return;

    final oldId = oldRestaurant['poi_id']?.toString() ?? oldRestaurant['name'];

    for (var day in itinerary) {
      final places = day['places'] as List?;
      if (places != null) {
        for (int i = 0; i < places.length; i++) {
          final place = places[i];
          final placeId = place['poi_id']?.toString() ?? place['name'];
          if (placeId == oldId) {
            // Replace with new restaurant
            places[i] = newRestaurant;
            return;
          }
        }
      }
    }
  }

  // Show delete confirmation for restaurant
  Future<bool> _showDeleteRestaurantConfirmation(Map<String, dynamic> restaurant) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _backgroundColor,
            title: Text('Delete Restaurant?', style: TextStyle(color: _textPrimary)),
            content: Text(
              'Are you sure you want to remove "${restaurant['name']}" from the itinerary?',
              style: TextStyle(color: _textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: _textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  _deleteRestaurant(restaurant);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Delete restaurant from itinerary
  void _deleteRestaurant(Map<String, dynamic> restaurant) {
    setState(() {
      final itinerary = widget.trip['itinerary'] as List?;
      if (itinerary != null) {
        for (var day in itinerary) {
          // ✅ Remove from restaurants[] array first
          final dayRestaurants = day['restaurants'] as List?;
          if (dayRestaurants != null) {
            dayRestaurants.removeWhere((r) =>
                (r['poi_id']?.toString() ?? r['name']) ==
                (restaurant['poi_id']?.toString() ?? restaurant['name']));
          }

          // ✅ FALLBACK: Also remove from places[] for backward compatibility
          final places = day['places'] as List?;
          if (places != null) {
            places.removeWhere((p) =>
                (p['poi_id']?.toString() ?? p['name']) ==
                (restaurant['poi_id']?.toString() ?? restaurant['name']));
          }
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${restaurant['name']} removed from itinerary'),
        backgroundColor: Colors.red.shade400,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  // Add new restaurant to itinerary (adds to first day)
  void _addNewRestaurant(Map<String, dynamic> restaurant) {
    final itinerary = widget.trip['itinerary'] as List?;
    if (itinerary == null || itinerary.isEmpty) return;

    // Add to the first day's places
    final firstDay = itinerary[0] as Map<String, dynamic>;
    final places = firstDay['places'] as List? ?? [];

    // Check if restaurant already exists
    final restaurantId = restaurant['poi_id']?.toString() ?? restaurant['name'];
    final exists = places.any((p) =>
      (p['poi_id']?.toString() ?? p['name']) == restaurantId
    );

    if (!exists) {
      places.add(restaurant);
      firstDay['places'] = places;
    }
  }


  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final dayNumber = day['day'] ?? (index + 1);
    final dayTitle = day['title'] ?? 'Day ${index + 1}';
    final isExpanded = _expandedDays[dayNumber] ?? false;
    final places = day['places'] as List?;
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedDays[dayNumber] = !isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text('$dayNumber',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(dayTitle,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary)),
                ),
                // Кнопка добавления места
                if (isExpanded)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: AppColors.primary,
                    onPressed: () => _addPlaceToDay(day),
                    tooltip: 'Add place',
                  ),
                Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _textSecondary,
                    size: 24),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 0, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (places != null && places.isNotEmpty) ...[
                        ...places.map((place) =>
                            _buildPlaceCard(place as Map<String, dynamic>)),
                      ],
                      // Кнопка "Add Place" внизу списка
                      if (places == null || places.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () => _addPlaceToDay(day),
                              icon: const Icon(Icons.add_location_alt_outlined),
                              label: const Text('Add first place'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ✅ КАРТОЧКА МЕСТА С iOS-СТИЛЬ СВАЙПОМ
  Widget _buildPlaceCard(Map<String, dynamic> place) {
    final placeId = place['poi_id']?.toString() ?? place['name'];
    final isSelected = _selectedPlaceIds.contains(placeId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(placeId),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.45,
          children: [
            CustomSlidableAction(
              onPressed: (_) => _editPlace(place),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 24),
                  SizedBox(height: 6),
                  Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (context) async {
                final confirm = await _showDeleteConfirmation(place);
                if (!confirm && context.mounted) {
                  // Закрываем свайп, если отменили
                  final slidableState = Slidable.of(context);
                  slidableState?.close();
                }
              },
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 24),
                  SizedBox(height: 6),
                  Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onLongPress: () => _showPlaceOptionsMenu(place),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlaceDetailsScreen(
                    place: place,
                    trip: widget.trip,
                    isDark: _isDark,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : (_isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey[50]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : (_isDark
                          ? Colors.white.withValues(alpha: 0.07)
                          : Colors.grey[200]!),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  _getPlacePreview(place),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (place['rating'] != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${place['rating']}",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            if (place['price'] != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.euro,
                                      color: Colors.green, size: 13),
                                  const SizedBox(width: 2),
                                  Text(
                                    place['price'],
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.green),
                                  ),
                                ],
                              ),
                            if (place['duration_minutes'] != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Colors.blue, size: 13),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${place['duration_minutes']} min',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.blue),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (place['image_url'] != null)
                    IconButton(
                      icon: const Icon(Icons.photo, size: 19),
                      color: isSelected ? AppColors.primary : Colors.blueAccent,
                      onPressed: () => _togglePlaceSelection(place),
                      tooltip: isSelected ? 'Remove filter' : 'Filter photos',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: _textSecondary, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getPlacePreview(Map<String, dynamic> place) {
    // ✅ Support both images[] array and image_url
    String? imageUrl;

    // Try to get first image from images[] array
    if (place['images'] != null && place['images'] is List) {
      final images = place['images'] as List;
      if (images.isNotEmpty && images[0] is Map) {
        imageUrl = (images[0] as Map)['url']?.toString();
      }
    }

    // Fallback to image_url
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = place['image_url'] as String?;
    }

    final category = place['category'] as String? ?? 'attraction';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _getCategoryIcon(category),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              },
            )
          : _getCategoryIcon(category),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;

    switch (category) {
      case 'attraction':
        icon = Icons.museum;
        color = AppColors.primary;
        break;
      case 'breakfast':
      case 'lunch':
      case 'dinner':
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      default:
        icon = Icons.place;
        color = Colors.grey;
    }

    return Center(
      child: Icon(icon, size: 24, color: color),
    );
  }


  Widget _buildBookButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'Book Now',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: (_isDark ? Colors.white : Colors.grey).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
