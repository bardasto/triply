import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../../core/constants/color_constants.dart';
import 'place_details_screen.dart';



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
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _mapSectionKey = GlobalKey();

  late TabController _tabController;
  int _currentImageIndex = 0;
  GoogleMapController? _mapController;
  bool _isMapExpanded = false;
  Set<Marker> _markers = {};
  final Map<int, bool> _expandedDays = {};

  final Set<String> _selectedPlaceIds = {};
  List<String> _filteredImages = [];

  bool get _isDark => widget.isDarkMode;

  Color get _backgroundColor =>
      _isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : AppColors.text;
  Color get _textSecondary =>
      _isDark ? Colors.white70 : AppColors.textSecondary;
  Color get _dividerColor => _isDark ? Colors.white12 : Colors.grey[200]!;

  LatLng get _tripLocation {
    try {
      double? lat;
      double? lng;

      if (widget.trip['latitude'] != null) {
        if (widget.trip['latitude'] is double) {
          lat = widget.trip['latitude'];
        } else if (widget.trip['latitude'] is num) {
          lat = widget.trip['latitude'].toDouble();
        } else if (widget.trip['latitude'] is String) {
          lat = double.tryParse(widget.trip['latitude']);
        }
      }
      if (widget.trip['longitude'] != null) {
        if (widget.trip['longitude'] is double) {
          lng = widget.trip['longitude'];
        } else if (widget.trip['longitude'] is num) {
          lng = widget.trip['longitude'].toDouble();
        } else if (widget.trip['longitude'] is String) {
          lng = double.tryParse(widget.trip['longitude']);
        }
      }
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    } catch (e) {
      debugPrint('❌ Error parsing coordinates: $e');
    }
    return const LatLng(48.8566, 2.3522);
  }

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

            // ✅ Берем только image_url (первое фото места)
            final imageUrl = place['image_url'];
            if (imageUrl != null && imageUrl is String && imageUrl.isNotEmpty) {
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
    _initializeMarker();
  }

  void _initializeMarker() {
    final location = _tripLocation;
    _markers = {
      Marker(
        markerId: const MarkerId('trip_location'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: widget.trip['city'] ?? 'Location',
          snippet: widget.trip['country'] ?? '',
        ),
      ),
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _mapController?.dispose();
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

  void _scrollToMap() {
    if (_mapSectionKey.currentContext != null) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        final RenderBox renderBox =
            _mapSectionKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final screenHeight = MediaQuery.of(context).size.height;
        final targetOffset =
            _scrollController.offset + position.dy - (screenHeight * 0.5) + 200;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
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
          if (place['image_url'] != null) {
            _filteredImages.add(place['image_url'] as String);
          }
        }
      }
    }
    if (_filteredImages.isEmpty && widget.trip['hero_image_url'] != null) {
      _filteredImages.add(widget.trip['hero_image_url'] as String);
    }
  }

  void _showPlaceOnMap(Map<String, dynamic> place) {
    final lat = (place['latitude'] as num?)?.toDouble();
    final lng = (place['longitude'] as num?)?.toDouble();
    if (lat != null && lng != null && _mapController != null) {
      final location = LatLng(lat, lng);
      setState(() {
        _markers = {
          Marker(
            markerId: MarkerId(place['name']),
            position: location,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: place['address'] ?? '',
            ),
          ),
        };
      });
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 15.0),
        ),
      );
      _scrollToMap();
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
                leading: const Icon(Icons.map, color: Colors.blue),
                title: Text('Show on Map',
                    style: TextStyle(color: _textPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  _showPlaceOnMap(place);
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
          Column(
            children: [
              _buildImageGallery(),
              Expanded(child: _buildScrollableContent()),
            ],
          ),
          _buildDragHandle(),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 285,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, index) => AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                }
                return Center(
                  child: SizedBox(
                    height: Curves.easeOut.transform(value) * 255,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                child: _buildImagePage(_images[index]),
              ),
            ),
          ),
          _buildPageIndicators(),
        ],
      ),
    );
  }

  Widget _buildImagePage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.white, size: 50)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _images.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentImageIndex == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentImageIndex == index
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Divider(height: 1, color: _dividerColor),
          _buildMapSection(),
          const SizedBox(height: 20),
          _buildBookButton(),
          const SizedBox(height: 40),
        ],
      ),
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

  // ✅ RESTAURANTS TAB - Breakfast, Lunch, Dinner
  Widget _buildRestaurantsTab(List<dynamic> itinerary) {
    // Collect all restaurants from all days
    final Map<String, List<Map<String, dynamic>>> restaurantsByCategory = {
      'breakfast': [],
      'lunch': [],
      'dinner': [],
    };

    for (var day in itinerary) {
      final places = day['places'] as List?;
      if (places != null) {
        for (var place in places) {
          final category = place['category'] as String?;
          if (category != null && restaurantsByCategory.containsKey(category)) {
            restaurantsByCategory[category]!.add(place as Map<String, dynamic>);
          }
        }
      }
    }

    // Check if there are any restaurants at all
    final hasAnyRestaurants = restaurantsByCategory.values.any((list) => list.isNotEmpty);

    if (!hasAnyRestaurants) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (restaurantsByCategory['breakfast']!.isNotEmpty) ...[
          _buildRestaurantCategory('Breakfast', restaurantsByCategory['breakfast']!, Icons.free_breakfast),
          const SizedBox(height: 16),
        ],
        if (restaurantsByCategory['lunch']!.isNotEmpty) ...[
          _buildRestaurantCategory('Lunch', restaurantsByCategory['lunch']!, Icons.lunch_dining),
          const SizedBox(height: 16),
        ],
        if (restaurantsByCategory['dinner']!.isNotEmpty)
          _buildRestaurantCategory('Dinner', restaurantsByCategory['dinner']!, Icons.dinner_dining),
      ],
    );
  }

  Widget _buildRestaurantCategory(String title, List<Map<String, dynamic>> restaurants, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...restaurants.map((restaurant) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRestaurantCard(restaurant),
        )),
      ],
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return GestureDetector(
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
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            _getPlacePreview(restaurant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (restaurant['rating'] != null) ...[
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "${restaurant['rating']}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (restaurant['price'] != null) ...[
                        const Icon(Icons.euro, color: Colors.green, size: 13),
                        const SizedBox(width: 2),
                        Text(
                          restaurant['price'],
                          style: const TextStyle(fontSize: 13, color: Colors.green),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.map, size: 19),
              onPressed: () => _showPlaceOnMap(restaurant),
              color: AppColors.primary,
              tooltip: 'Show on map',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: _textSecondary, size: 22),
          ],
        ),
      ),
    );
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
                  IconButton(
                    icon: const Icon(Icons.map, size: 19),
                    onPressed: () => _showPlaceOnMap(place),
                    color: AppColors.primary,
                    tooltip: 'Show on map',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
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
    final imageUrl = place['image_url'] as String?;
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

  Widget _buildMapSection() {
    final location = _tripLocation;
    return Padding(
      key: _mapSectionKey,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary)),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isMapExpanded ? 400 : 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: location, zoom: 13.0),
                    mapType: MapType.normal,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                    buildingsEnabled: true,
                    trafficEnabled: false,
                    zoomGesturesEnabled: _isMapExpanded,
                    scrollGesturesEnabled: _isMapExpanded,
                    tiltGesturesEnabled: _isMapExpanded,
                    rotateGesturesEnabled: _isMapExpanded,
                    gestureRecognizers: _isMapExpanded
                        ? <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer()),
                          }
                        : {},
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                  ),
                  if (!_isMapExpanded)
                    Positioned.fill(
                        child: Container(color: Colors.transparent)),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isMapExpanded = !_isMapExpanded;
                        });
                        if (_isMapExpanded) {
                          _scrollToMap();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Icon(
                            _isMapExpanded
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            size: 20,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
