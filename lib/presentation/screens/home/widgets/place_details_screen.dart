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
  bool _scheduleExpanded = false;
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
      print('Images content: ${place['images']}');
    }
    print('Has image_url: ${place['image_url'] != null}');
    if (place['image_url'] != null) {
      print('image_url: ${place['image_url']}');
    }
    print('═══════════════════════════════════════');

    // ✅ 1. Проверяем массив images[] (новая структура - несколько фото)
    if (place['images'] != null && place['images'] is List) {
      final placeImages = (place['images'] as List)
          .where((img) => img != null && img.toString().isNotEmpty)
          .map((img) => img.toString())
          .toList();

      if (placeImages.isNotEmpty) {
        images.addAll(placeImages);
        print('✅ Loaded ${placeImages.length} images from images[] array');
      } else {
        print('⚠️ images[] array is empty');
      }
    } else {
      print('⚠️ No images[] array found');
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
                          child: Text(
                            place['description'],
                            style: TextStyle(
                              fontSize: 15.3,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              height: 1.46,
                            ),
                          ),
                        ),

                      // Price, Duration, Schedule
                      if (place['price'] != null)
                        _ParamRow(
                          icon: Icons.euro,
                          label: 'Price',
                          value: place['price'],
                          isDark: isDark,
                        ),
                      if (place['duration_minutes'] != null)
                        _ParamRow(
                          icon: Icons.access_time,
                          label: 'Duration',
                          value: '${place['duration_minutes']} min',
                          isDark: isDark,
                        ),
                      _ExpandableSchedule(
                        expanded: _scheduleExpanded,
                        onExpand: (e) => setState(() => _scheduleExpanded = e),
                        schedule: _parseWeekSchedule(
                            place['weekly_schedule'], place['opening_hours']),
                        isDark: isDark,
                      ),
                      if (place['cuisine'] != null && (place['cuisine'] as String).isNotEmpty)
                        _ParamRow(
                          icon: Icons.restaurant_menu,
                          label: 'Cuisine',
                          value: place['cuisine'],
                          isDark: isDark,
                        ),

                      // Address
                      if (place['address'] != null)
                        GestureDetector(
                          onTap: () => _showAddressOptions(context),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.place_outlined,
                                    size: 18, color: Colors.redAccent),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    place['address'],
                                    style: TextStyle(
                                      color: Colors.redAccent.withValues(alpha: 0.96),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

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

  List<MapEntry<String, String>> _parseWeekSchedule(
      dynamic weekly, String? fallback) {
    if (weekly is List) {
      final days = <MapEntry<String, String>>[];
      for (var entry in weekly) {
        days.add(MapEntry(
          entry['day'] ?? '',
          (entry['open'] ?? '') +
              (entry['close'] != null ? ' – ${entry['close']}' : ''),
        ));
      }
      return days;
    }

    if (fallback != null) {
      return [MapEntry('', fallback)];
    }

    return [];
  }
}

class _ParamRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ParamRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 9),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSchedule extends StatelessWidget {
  final bool expanded;
  final void Function(bool) onExpand;
  final List<MapEntry<String, String>> schedule;
  final bool isDark;

  const _ExpandableSchedule({
    required this.expanded,
    required this.onExpand,
    required this.schedule,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (schedule.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onExpand(!expanded),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 9),
              const Text(
                "Schedule: ",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: Colors.white70,
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          crossFadeState:
              expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeOut,
          firstChild: Padding(
            padding:
                const EdgeInsets.only(left: 31, right: 4, top: 4, bottom: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: schedule
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 2.5),
                      child: Text(
                        e.key.isNotEmpty ? "${e.key}: ${e.value}" : e.value,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          secondChild: const SizedBox(height: 7),
        ),
      ],
    );
  }
}
