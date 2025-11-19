import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;
  final Map<String, dynamic>? trip;
  final bool isDark;

  const PlaceDetailsScreen({
    Key? key,
    required this.place,
    required this.isDark,
    this.trip,
  }) : super(key: key);

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  bool _isOpeningHoursExpanded = false;
  bool _isDescriptionExpanded = false;
  bool _isPriceExpanded = false;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// ✅ UPDATED: Получаем НЕСКОЛЬКО фотографий этого конкретного места
  /// ✅ UPDATED: Получаем НЕСКОЛЬКО фотографий этого конкретного места
  List<String> _getPlaceImages() {
    final List<String> images = [];
    final place = widget.place;

    // 🔍 DEBUG: Выводим структуру place
    print('═══════════════════════════════════════');
    print('🔍 DEBUG: Place data structure');
    print('Place name: ${place['name']}');
    print('Has images array: ${place['images'] != null}');
    if (place['images'] != null) {
      print('Images array type: ${place['images'].runtimeType}');
      print('Images array length: ${(place['images'] as List?)?.length ?? 0}');
      if ((place['images'] as List).isNotEmpty) {
        print('First element type: ${(place['images'] as List)[0].runtimeType}');
        print('First element content: ${(place['images'] as List)[0]}');
        try {
          final firstImg = (place['images'] as List)[0];
          print('Can access as Map? ${firstImg is Map}');
          print('First img["url"]: ${firstImg["url"]}');
        } catch (e) {
          print('ERROR accessing first image: $e');
        }
      }
    }
    print('Has image_url: ${place['image_url'] != null}');
    if (place['image_url'] != null) {
      print('image_url: ${place['image_url']}');
    }
    print('═══════════════════════════════════════');

    // ✅ 1. Проверяем массив images[] (новая структура - несколько фото)
    if (place['images'] != null && place['images'] is List) {
      final placeImages = (place['images'] as List)
          .where((img) => img != null && img is Map)
          .map((img) => (img as Map)['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      if (placeImages.isNotEmpty) {
        images.addAll(placeImages);
      }
    }

    // ✅ 2. Fallback: если нет images[], используем image_url (старая структура)
    if (images.isEmpty) {
      final imageUrl = place['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images.add(imageUrl);
        print('✅ Fallback: Using image_url (1 photo)');
      } else {
        print('⚠️ No image_url found either');
      }
    }

    print('📸 Final result: ${images.length} total images');
    print('═══════════════════════════════════════\n');

    return images;
  }


  /// Показать меню с опциями для адреса
  void _showAddressOptions(BuildContext context) {
    final place = widget.place;
    final isDark = widget.isDark;
    final address = place['address'] as String?;
    final double lat = (place['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (place['longitude'] as num?)?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2C2C2C).withValues(alpha: 0.99)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              context,
              icon: Icons.content_copy,
              title: 'Copy address',
              onTap: () {
                Navigator.pop(context);
                _copyAddress(address);
              },
              isDark: isDark,
            ),
            _buildOptionTile(
              context,
              icon: Icons.gps_fixed,
              title: 'Copy GPS coordinates',
              onTap: () {
                Navigator.pop(context);
                _copyCoordinates(lat, lng);
              },
              isDark: isDark,
            ),
            _buildOptionTile(
              context,
              icon: Icons.map,
              title: 'Open in Maps',
              onTap: () {
                Navigator.pop(context);
                _openInAppleMaps(lat, lng);
              },
              isDark: isDark,
            ),
            _buildOptionTile(
              context,
              icon: Icons.map_outlined,
              title: 'Open in Google maps',
              onTap: () {
                Navigator.pop(context);
                _openInGoogleMaps(lat, lng);
              },
              isDark: isDark,
            ),
            const Divider(height: 1),
            _buildOptionTile(
              context,
              icon: Icons.close,
              title: 'Cancel',
              onTap: () => Navigator.pop(context),
              isDark: isDark,
              isCancel: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
          ),
        ),
      ),
    );
  }

  /// Элемент меню
  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isCancel = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isCancel ? Colors.red : (isDark ? Colors.white70 : Colors.black87),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isCancel ? Colors.red : (isDark ? Colors.white : Colors.black87),
          fontWeight: isCancel ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }

  /// Копировать адрес
  void _copyAddress(String? address) {
    if (address != null && address.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: address));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Копировать GPS координаты
  void _copyCoordinates(double lat, double lng) {
    final coordinates = '$lat, $lng';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS coordinates copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Открыть в Apple Maps
  Future<void> _openInAppleMaps(double lat, double lng) async {
    final url = Uri.parse('http://maps.apple.com/?ll=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Maps')),
        );
      }
    }
  }

  /// Открыть в Google Maps
  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  /// Format price level to euros string (e.g., 2 -> "€€")
  String? _formatPriceLevel(dynamic priceLevel) {
    if (priceLevel == null) return null;

    int level = 0;
    if (priceLevel is int) {
      level = priceLevel;
    } else if (priceLevel is String) {
      level = int.tryParse(priceLevel) ?? 0;
    } else if (priceLevel is double) {
      level = priceLevel.round();
    }

    if (level <= 0 || level > 4) return null;

    return '€' * level;
  }

  /// Format cuisine types array to display string (e.g., ["Italian", "Pizza"] -> "Italian, Pizza")
  String? _formatCuisineTypes(dynamic cuisineTypes) {
    if (cuisineTypes == null) return null;

    if (cuisineTypes is List && cuisineTypes.isNotEmpty) {
      final types = cuisineTypes
          .where((type) => type != null && type.toString().isNotEmpty)
          .map((type) => type.toString())
          .toList();

      if (types.isEmpty) return null;

      return types.join(', ');
    } else if (cuisineTypes is String && cuisineTypes.isNotEmpty) {
      return cuisineTypes;
    }

    return null;
  }

  /// Get opening status text (e.g., "Open" or "Closed")
  String _getOpeningStatus(dynamic openingHours) {
    print('═══════════════════════════════════════');
    print('🕐 DEBUG: Opening Hours Status');
    print('openingHours type: ${openingHours.runtimeType}');
    print('openingHours value: $openingHours');

    if (openingHours == null) {
      print('❌ openingHours is null');
      print('═══════════════════════════════════════\n');
      return 'Hours not available';
    }

    // ✅ Handle String format (e.g., "9:00 - 18:00")
    if (openingHours is String) {
      print('✅ openingHours is String: $openingHours');
      print('═══════════════════════════════════════\n');
      if (openingHours.trim().isEmpty) {
        return 'Hours not available';
      }
      // Return the hours string as-is
      return openingHours;
    }

    // ✅ Handle Map format (Google Places API format)
    if (openingHours is Map<String, dynamic>) {
      final openNow = openingHours['open_now'] as bool?;
      final weekdayText = openingHours['weekday_text'] as List?;

      print('open_now: $openNow');
      print('weekday_text: $weekdayText');

      if (weekdayText == null || weekdayText.isEmpty) {
        print('❌ weekday_text is null or empty');
        print('═══════════════════════════════════════\n');
        return 'Hours not available';
      }

      // Get current day (0 = Sunday, 1 = Monday, etc.)
      final now = DateTime.now();
      final currentDay = now.weekday % 7;

      // Get today's hours from weekday_text
      String todayHours = '';
      if (weekdayText.length > currentDay) {
        todayHours = weekdayText[currentDay].toString();
        if (todayHours.contains(':')) {
          todayHours = todayHours.split(':').skip(1).join(':').trim();
        }
      }

      if (todayHours.toLowerCase().contains('closed')) {
        return 'Closed';
      }

      if (openNow == true) {
        return 'Open';
      } else {
        return 'Closed';
      }
    }

    print('❌ openingHours is neither String nor Map');
    print('═══════════════════════════════════════\n');
    return 'Hours not available';
  }

  /// Get list of weekday hours
  List<String> _getWeekdayHours(dynamic openingHours) {
    if (openingHours == null) {
      return [];
    }

    // ✅ If it's a String, we don't have detailed weekday hours
    if (openingHours is String) {
      return [];
    }

    // ✅ If it's a Map, try to get weekday_text
    if (openingHours is Map<String, dynamic>) {
      final weekdayText = openingHours['weekday_text'] as List?;
      if (weekdayText == null || weekdayText.isEmpty) {
        return [];
      }
      return weekdayText.map((e) => e.toString()).toList();
    }

    return [];
  }

  /// Open website in browser
  Future<void> _openWebsite(String? website) async {
    if (website == null || website.isEmpty) return;

    final url = Uri.parse(website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final isDark = widget.isDark;
    final images = _getPlaceImages();
    final safeTop = MediaQuery.of(context).padding.top;
    final double lat = (place['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (place['longitude'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // ✅ Image Gallery (swipeable если > 1 фото)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 280 + safeTop,
                        child: images.isEmpty
                            ? Container(
                                color: Colors.grey,
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 54, color: Colors.white38),
                                ),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemCount: images.length,
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    images[index],
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    height: 280 + safeTop,
                                    width: double.infinity,
                                    errorBuilder: (c, e, s) => Container(
                                      color: Colors.grey,
                                      child: const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 54, color: Colors.white38),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    // ✅ Image counter badge (только если больше 1 фото)
                    if (images.length > 1)
                      Positioned(
                        top: safeTop + 12,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                '${_currentImageIndex + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ✅ Page indicators (только если больше 1 фото)
                    if (images.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length > 5 ? 5 : images.length,
                            (index) {
                              int displayIndex = index;
                              if (images.length > 5 && index == 4) {
                                displayIndex = images.length - 1;
                              }

                              final isActive =
                                  _currentImageIndex == displayIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              place['name'] ?? '',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: -0.2,
                                height: 1.1,
                              ),
                              maxLines: 2,
                            ),
                          ),
                          if (place['rating'] != null) ...[
                            const SizedBox(width: 9),
                            Icon(Icons.star,
                                color: Colors.amber.shade600, size: 18),
                            Text(
                              place['rating'].toString(),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (place['category'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            place['category'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (place['description'] != null &&
                          (place['description'] as String).trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 13, bottom: 13),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  place['description'],
                                  style: TextStyle(
                                    fontSize: 15.3,
                                    color: isDark ? Colors.white70 : Colors.grey[700],
                                    height: 1.46,
                                  ),
                                  maxLines: _isDescriptionExpanded ? null : 3,
                                  overflow: _isDescriptionExpanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                              ),
                              if ((place['description'] as String).length > 100) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded = !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Text(
                                    _isDescriptionExpanded ? 'See less' : 'See more',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Unified Info Block (Opening Hours, Address, Website, Price, Cuisine)
                      _buildUnifiedInfoBlock(
                        openingHours: place['opening_hours'],
                        address: place['address'] as String?,
                        website: place['website'] as String?,
                        price: _formatPriceLevel(place['price_level']) ?? place['price'] as String?,
                        cuisine: _formatCuisineTypes(place['cuisine_types']) ?? place['cuisine'] as String?,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 16),

                      // Ratings & Reviews Section
                      if (place['rating'] != null || place['google_rating'] != null) ...[
                        Text(
                          'Ratings & reviews',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildReviewsSection(
                          rating: (place['rating'] ?? place['google_rating']) as double?,
                          reviewCount: (place['review_count'] ??
                              place['google_review_count'] ??
                              0) as int,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Map
                      if (lat != 0 && lng != 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(19),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.07),
                                  blurRadius: 12,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(lat, lng),
                              zoom: 15,
                            ),
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            markers: {
                              Marker(
                                markerId: const MarkerId('place'),
                                position: LatLng(lat, lng),
                              ),
                            },
                            liteModeEnabled: true,
                            scrollGesturesEnabled: false,
                            tiltGesturesEnabled: false,
                            rotateGesturesEnabled: false,
                            mapType: MapType.normal,
                          ),
                        ),
                      ],

                      // Transport
                      if (place['transportation'] != null) ...[
                        const SizedBox(height: 19),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? Colors.black12
                                : Colors.orange.withValues(alpha: 0.07),
                          ),
                          padding: const EdgeInsets.fromLTRB(13, 8, 13, 8),
                          child: Row(
                            children: [
                              Icon(
                                  _getTransportIcon(place['transportation']
                                      ['method'] as String),
                                  color: Colors.orange,
                                  size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "Travel: ",
                                        style: TextStyle(
                                          fontSize: 15.2,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'by ${place['transportation']['method']}'
                                            ' ${place['transportation']['duration_minutes']} min'
                                            '${place['transportation']['cost'] != null ? ' (${place['transportation']['cost']})' : ''}',
                                        style: TextStyle(
                                          fontSize: 15.2,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Back button
          Positioned(
            top: safeTop + 12,
            left: 8,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(7),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 23, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Unified info block with opening hours, address, website, price, and cuisine
  Widget _buildUnifiedInfoBlock({
    required dynamic openingHours,
    required String? address,
    required String? website,
    String? price,
    String? cuisine,
    required bool isDark,
  }) {
    final hasAddress = address != null && address.isNotEmpty;
    final hasWebsite = website != null && website.isNotEmpty;
    final hasPrice = price != null && price.isNotEmpty;
    final hasCuisine = cuisine != null && cuisine.isNotEmpty;

    // Build list of sections
    final List<Widget> sections = [];

    // Opening Hours
    sections.add(_buildOpeningHoursSectionCompact(openingHours, isDark));

    // Price
    if (hasPrice) {
      sections.add(Container(
        height: 5,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
      ));
      sections.add(_buildPriceSectionCompact(price, isDark));
    }

    // Cuisine
    if (hasCuisine) {
      sections.add(Container(
        height: 5,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
      ));
      sections.add(_buildCuisineSectionCompact(cuisine, isDark));
    }

    // Address
    if (hasAddress) {
      sections.add(Container(
        height: 5,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
      ));
      sections.add(_buildAddressSectionCompact(address, isDark));
    }

    // Website
    if (hasWebsite) {
      sections.add(Container(
        height: 5,
        color: isDark ? const Color(0xFF1C1C1E) : Colors.grey[200],
      ));
      sections.add(_buildWebsiteSectionCompact(website, isDark));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: sections),
    );
  }

  /// Opening Hours Section (compact version without container)
  Widget _buildOpeningHoursSectionCompact(dynamic openingHours, bool isDark) {
    final openingStatus = _getOpeningStatus(openingHours);
    final weekdayHours = _getWeekdayHours(openingHours);
    final hasHours = weekdayHours.isNotEmpty;

    // Determine icon color based on status
    Color iconColor;
    Color textColor;
    if (openingStatus.toLowerCase().contains('closed')) {
      iconColor = Colors.red;
      textColor = Colors.red;
    } else if (openingStatus.toLowerCase().contains('open')) {
      iconColor = Colors.green;
      textColor = Colors.green;
    } else {
      // For time strings like "9:00 - 18:00"
      iconColor = isDark ? Colors.white70 : Colors.black87;
      textColor = isDark ? Colors.white : Colors.black87;
    }

    return GestureDetector(
      onTap: hasHours
          ? () {
              setState(() {
                _isOpeningHoursExpanded = !_isOpeningHoursExpanded;
              });
            }
          : null,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: iconColor,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    openingStatus,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                if (hasHours)
                  Icon(
                    _isOpeningHoursExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                    size: 24,
                  ),
              ],
            ),
            if (_isOpeningHoursExpanded && hasHours) ...[
              const SizedBox(height: 16),
              Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF3C3C3E) : Colors.grey[300]),
              const SizedBox(height: 12),
              ...weekdayHours.map((dayHours) {
                final parts = dayHours.split(':');
                final day = parts[0].trim();
                final hours =
                    parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        hours,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Address Section (compact version without container)
  Widget _buildAddressSectionCompact(String address, bool isDark) {
    return GestureDetector(
      onTap: () => _showAddressOptions(context),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black.withValues(alpha: 0.9),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// Website Section (compact version without container)
  Widget _buildWebsiteSectionCompact(String website, bool isDark) {
    String displayUrl = website;
    try {
      final uri = Uri.parse(website);
      displayUrl = uri.host.replaceAll('www.', '');
    } catch (_) {}

    return GestureDetector(
      onTap: () => _openWebsite(website),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.language,
              color: Colors.blue,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayUrl,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black.withValues(alpha: 0.9),
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  /// Price Section (compact version without container)
  Widget _buildPriceSectionCompact(String price, bool isDark) {
    // Check if place has detailed pricing info
    final place = widget.place;
    final hasPriceDetails = place['price_details'] != null;

    return GestureDetector(
      onTap: hasPriceDetails
          ? () {
              setState(() {
                _isPriceExpanded = !_isPriceExpanded;
              });
            }
          : null,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.euro,
                  color: Colors.green,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Price - ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.9),
                          ),
                        ),
                        TextSpan(
                          text: '$price per person',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasPriceDetails)
                  Icon(
                    _isPriceExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                    size: 24,
                  ),
              ],
            ),
            if (_isPriceExpanded && hasPriceDetails) ...[
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF3C3C3E) : Colors.grey[300],
              ),
              const SizedBox(height: 12),
              _buildPriceDetails(place['price_details'], isDark),
            ],
          ],
        ),
      ),
    );
  }

  /// Build detailed price information
  Widget _buildPriceDetails(dynamic priceDetails, bool isDark) {
    if (priceDetails == null) return const SizedBox.shrink();

    // Handle Map format (e.g., {"adult": "€50", "child": "€25", "senior": "€40"})
    if (priceDetails is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: priceDetails.entries.map((entry) {
          final category = _formatPriceCategory(entry.key);
          final price = entry.value.toString();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Handle String format with line breaks
    if (priceDetails is String) {
      final lines = priceDetails.split('\n').where((l) => l.trim().isNotEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line.trim(),
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.8),
              ),
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }

  /// Format price category (e.g., "adult" -> "Adult", "child" -> "Child")
  String _formatPriceCategory(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }

  /// Cuisine Section (compact version without container)
  Widget _buildCuisineSectionCompact(String cuisine, bool isDark) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_menu,
            color: Colors.orange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Cuisine - ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.9),
                    ),
                  ),
                  TextSpan(
                    text: cuisine,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7),
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

  /// Reviews Section with rating breakdown
  Widget _buildReviewsSection({
    required double? rating,
    required int reviewCount,
    required bool isDark,
  }) {
    if (rating == null || rating == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No ratings available',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating Summary Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Large Rating Number
              Column(
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < rating.floor()
                            ? Icons.star
                            : (index < rating
                                ? Icons.star_half
                                : Icons.star_border),
                        color: Colors.amber,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$reviewCount reviews',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),

              // Rating Breakdown
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.7, reviewCount, isDark),
                    const SizedBox(height: 8),
                    _buildRatingBar(4, 0.2, reviewCount, isDark),
                    const SizedBox(height: 8),
                    _buildRatingBar(3, 0.07, reviewCount, isDark),
                    const SizedBox(height: 8),
                    _buildRatingBar(2, 0.02, reviewCount, isDark),
                    const SizedBox(height: 8),
                    _buildRatingBar(1, 0.01, reviewCount, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build rating bar with percentage
  Widget _buildRatingBar(
      int stars, double percentage, int totalReviews, bool isDark) {
    final count = (totalReviews * percentage).round();

    return Row(
      children: [
        Text(
          '$stars',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            count > 0 ? '$count' : '',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  IconData _getTransportIcon(String method) {
    switch (method) {
      case 'walk':
        return Icons.directions_walk;
      case 'metro':
        return Icons.subway;
      case 'bus':
        return Icons.directions_bus;
      case 'taxi':
        return Icons.local_taxi;
      default:
        return Icons.directions;
    }
  }

}
