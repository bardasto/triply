import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/color_constants.dart';

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

  // Scroll controller for blur header
  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;

  // Precomputed blur layer configurations for smooth transition
  // Each layer: [topMultiplier, heightMultiplier, blurMultiplier]
  static const List<List<double>> _blurLayers = [
    [0.0, 0.35, 1.0],    // Top layer - strongest blur
    [0.25, 0.25, 0.85],  // Upper-mid layer
    [0.40, 0.20, 0.65],  // Mid layer
    [0.55, 0.18, 0.45],  // Lower-mid layer
    [0.68, 0.16, 0.25],  // Lower layer
    [0.80, 0.12, 0.12],  // Bottom layer - lightest blur
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    final newOffset = _scrollController.offset;
    if ((_scrollOffset - newOffset).abs() > 1) {
      setState(() => _scrollOffset = newOffset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- Методы переключения фото по тапу ---
  void _nextImage(int totalImages) {
    if (_currentImageIndex < totalImages - 1) {
      _pageController.animateToPage(
        _currentImageIndex + 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevImage() {
    if (_currentImageIndex > 0) {
      _pageController.animateToPage(
        _currentImageIndex - 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }
  // ----------------------------------------

  List<String> _getPlaceImages() {
    final List<String> images = [];
    final place = widget.place;

    if (place['images'] != null && place['images'] is List) {
      final imagesList = place['images'] as List;
      for (final img in imagesList) {
        String? url;
        if (img is String) {
          url = img;
        } else if (img is Map && img['url'] != null) {
          url = img['url'].toString();
        }
        if (url != null && url.isNotEmpty) {
          images.add(url);
        }
      }
    }

    if (images.isEmpty) {
      final imageUrl = place['image_url'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images.add(imageUrl);
      }
    }

    return images;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

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
                ? AppColors.secondaryDarkBackground.withValues(alpha: 0.99)
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
        color:
            isCancel ? Colors.red : (isDark ? Colors.white70 : Colors.black87),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color:
              isCancel ? Colors.red : (isDark ? Colors.white : Colors.black87),
          fontWeight: isCancel ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }

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

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
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

  String _getOpeningStatus(dynamic openingHours) {
    if (openingHours == null) return 'Hours not available';
    if (openingHours is String) {
      if (openingHours.trim().isEmpty) return 'Hours not available';
      return openingHours;
    }
    if (openingHours is Map<String, dynamic>) {
      final openNow = openingHours['open_now'] as bool?;
      final weekdayText = openingHours['weekday_text'] as List?;
      if (weekdayText == null || weekdayText.isEmpty) {
        return 'Hours not available';
      }
      final now = DateTime.now();
      final currentDay = now.weekday % 7;
      String todayHours = '';
      if (weekdayText.length > currentDay) {
        todayHours = weekdayText[currentDay].toString();
        if (todayHours.contains(':')) {
          todayHours = todayHours.split(':').skip(1).join(':').trim();
        }
      }
      if (todayHours.toLowerCase().contains('closed')) return 'Closed';
      if (openNow == true) {
        return 'Open';
      } else {
        return 'Closed';
      }
    }
    return 'Hours not available';
  }

  List<String> _getWeekdayHours(dynamic openingHours) {
    if (openingHours == null) return [];
    if (openingHours is String) return [];
    if (openingHours is Map<String, dynamic>) {
      final weekdayText = openingHours['weekday_text'] as List?;
      if (weekdayText == null || weekdayText.isEmpty) return [];
      return weekdayText.map((e) => e.toString()).toList();
    }
    return [];
  }

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

  /// Trims text to last complete word before maxLength
  String _trimToLastWord(String text, int maxLength) {
    if (text.length <= maxLength) return text;

    final trimmed = text.substring(0, maxLength);
    final lastSpace = trimmed.lastIndexOf(' ');

    if (lastSpace > 0) {
      return trimmed.substring(0, lastSpace);
    }
    return trimmed;
  }

  Widget _buildDescriptionText(String description, bool isDark) {
    const int trimLength = 150;

    final textStyle = TextStyle(
      fontSize: 15.5,
      color: isDark ? Colors.white70 : Colors.grey[700],
      height: 1.5,
    );

    if (description.length <= trimLength) {
      return Text(description, style: textStyle);
    }

    final trimmedText = _trimToLastWord(description, trimLength);

    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          TextSpan(
            text: _isDescriptionExpanded ? description : '$trimmedText... ',
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
              child: Text(
                _isDescriptionExpanded ? ' See less' : 'See more',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 320 + safeTop,
                    child: Stack(
                      children: [
                        // 1. Галерея изображений
                        if (images.isEmpty)
                          Container(
                            color: Colors.grey,
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 54, color: Colors.white38),
                            ),
                          )
                        else
                          PageView.builder(
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
                                width: double.infinity,
                                height: double.infinity,
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

                        // 2. Обработчик нажатий (Лево/Право) - как в Telegram
                        if (images.isNotEmpty)
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapUp: (details) {
                              final width = MediaQuery.of(context).size.width;
                              if (details.localPosition.dx < width / 2) {
                                _prevImage();
                              } else {
                                _nextImage(images.length);
                              }
                            },
                          ),

                        // 3. Градиент снизу для читаемости индикатора
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 80,
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

                        // 4. Индикатор-полоски (Telegram-style) СНИЗУ
                        if (images.length > 1)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 12,
                            child: Row(
                              children: List.generate(images.length, (index) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: index == _currentImageIndex
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.3),
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
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
                                fontSize: 24,
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
                                color: Colors.amber.shade600, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              place['rating'].toString(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (place['category'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            place['category'],
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (place['description'] != null &&
                          (place['description'] as String).trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 16),
                          child: _buildDescriptionText(
                            place['description'] as String,
                            isDark,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Unified Info Block
                      _buildUnifiedInfoBlock(
                        openingHours: place['opening_hours'],
                        address: place['address'] as String?,
                        website: place['website'] as String?,
                        price: _formatPriceLevel(place['price_level']) ??
                            place['price'] as String?,
                        cuisine: _formatCuisineTypes(place['cuisine_types']) ??
                            place['cuisine'] as String?,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 24),

                      // Ratings & Reviews Section
                      if (place['rating'] != null ||
                          place['google_rating'] != null) ...[
                        Text(
                          'Ratings & reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildReviewsSection(
                          rating: _parseDouble(place['rating'] ?? place['google_rating']),
                          reviewCount: _parseInt(place['review_count'] ??
                              place['google_review_count'] ??
                              0),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Map
                      if (lat != 0 && lng != 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
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
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isDark
                                ? Colors.black12
                                : Colors.orange.withValues(alpha: 0.07),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                  _getTransportIcon(place['transportation']
                                      ['method'] as String),
                                  color: Colors.orange,
                                  size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: "Travel: ",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'by ${place['transportation']['method']}'
                                            ' ${place['transportation']['duration_minutes']} min'
                                            '${place['transportation']['cost'] != null ? ' (${place['transportation']['cost']})' : ''}',
                                        style: TextStyle(
                                          fontSize: 16,
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
          // Blur header
          _buildBlurHeader(safeTop, isDark),
          // Back button
          Positioned(
            top: safeTop + 12,
            left: 16,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurHeader(double safeTop, bool isDark) {
    if (_scrollOffset <= 0) return const SizedBox.shrink();

    const blur = 20.0;
    final totalHeight = safeTop + 56;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: totalHeight,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
              // Build all blur layers from precomputed config
              for (final layer in _blurLayers)
                _buildBlurLayer(
                  totalHeight * layer[0],
                  totalHeight * layer[1],
                  blur,
                  layer[2],
                ),
              // Gradient overlay for smooth fade-out effect
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bgColor.withValues(alpha: 0.9),
                        bgColor.withValues(alpha: 0.7),
                        bgColor.withValues(alpha: 0.4),
                        bgColor.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.55, 0.8, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlurLayer(double top, double height, double blur, double multiplier) {
    // Skip rendering if blur would be imperceptible
    if (blur * multiplier < 0.5) return const SizedBox.shrink();

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blur * multiplier,
            sigmaY: blur * multiplier,
            tileMode: TileMode.clamp,
          ),
          child: const ColoredBox(color: Colors.transparent),
        ),
      ),
    );
  }

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

    final List<Widget> sections = [];
    sections.add(_buildOpeningHoursSectionCompact(openingHours, isDark));

    if (hasPrice) {
      sections.add(Container(
          height: 1,
          color: isDark ? AppColors.tertiaryDarkBackground : Colors.grey[200]));
      sections.add(_buildPriceSectionCompact(price, isDark));
    }
    if (hasCuisine) {
      sections.add(Container(
          height: 1,
          color: isDark ? AppColors.tertiaryDarkBackground : Colors.grey[200]));
      sections.add(_buildCuisineSectionCompact(cuisine, isDark));
    }
    if (hasAddress) {
      sections.add(Container(
          height: 1,
          color: isDark ? AppColors.tertiaryDarkBackground : Colors.grey[200]));
      sections.add(_buildAddressSectionCompact(address, isDark));
    }
    if (hasWebsite) {
      sections.add(Container(
          height: 1,
          color: isDark ? AppColors.tertiaryDarkBackground : Colors.grey[200]));
      sections.add(_buildWebsiteSectionCompact(website, isDark));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.secondaryDarkBackground : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: sections),
    );
  }

  Widget _buildOpeningHoursSectionCompact(dynamic openingHours, bool isDark) {
    final openingStatus = _getOpeningStatus(openingHours);
    final weekdayHours = _getWeekdayHours(openingHours);
    final hasHours = weekdayHours.isNotEmpty;
    Color iconColor;
    Color textColor;
    if (openingStatus.toLowerCase().contains('closed')) {
      iconColor = Colors.red;
      textColor = Colors.red;
    } else if (openingStatus.toLowerCase().contains('open')) {
      iconColor = Colors.green;
      textColor = Colors.green;
    } else {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(openingStatus,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                ),
                if (hasHours)
                  Icon(
                      _isOpeningHoursExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.5),
                      size: 20),
              ],
            ),
            if (_isOpeningHoursExpanded && hasHours) ...[
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: isDark ? AppColors.tertiaryDarkBackground : Colors.grey[300]),
              const SizedBox(height: 12),
              ...weekdayHours.map((dayHours) {
                final parts = dayHours.split(':');
                final day = parts[0].trim();
                final hours =
                    parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(day,
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.black.withValues(alpha: 0.9))),
                      Text(hours,
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.black.withValues(alpha: 0.7))),
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

  Widget _buildAddressSectionCompact(String address, bool isDark) {
    return GestureDetector(
      onTap: () => _showAddressOptions(context),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(address,
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.9)))),
            Icon(Icons.chevron_right,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
                size: 20),
          ],
        ),
      ),
    );
  }

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.language, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(displayUrl,
                    style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.9)))),
            Icon(Icons.open_in_new,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.4),
                size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSectionCompact(String price, bool isDark) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.euro, color: Colors.green, size: 20),
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
                                    : Colors.black.withValues(alpha: 0.9))),
                        TextSpan(
                            text: '$price per person',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.black.withValues(alpha: 0.7))),
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
                      size: 20),
              ],
            ),
            if (_isPriceExpanded && hasPriceDetails) ...[
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: isDark ? AppColors.tertiaryDarkBackground : Colors.grey[300]),
              const SizedBox(height: 12),
              _buildPriceDetails(place['price_details'], isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails(dynamic priceDetails, bool isDark) {
    if (priceDetails == null) return const SizedBox.shrink();
    if (priceDetails is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: priceDetails.entries.map((entry) {
          final category = _formatPriceCategory(entry.key);
          final price = entry.value.toString();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category,
                    style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.black.withValues(alpha: 0.9))),
                Text(price,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.7))),
              ],
            ),
          );
        }).toList(),
      );
    }
    if (priceDetails is String) {
      final lines = priceDetails.split('\n').where((l) => l.trim().isNotEmpty);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(line.trim(),
                style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.8))),
          );
        }).toList(),
      );
    }
    return const SizedBox.shrink();
  }

  String _formatPriceCategory(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }

  Widget _buildCuisineSectionCompact(String cuisine, bool isDark) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.restaurant_menu, color: Colors.orange, size: 20),
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
                              : Colors.black.withValues(alpha: 0.9))),
                  TextSpan(
                      text: cuisine,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.black.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.secondaryDarkBackground : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(rating.toStringAsFixed(1),
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black)),
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
                            )),
                  ),
                  const SizedBox(height: 8),
                  Text('$reviewCount reviews',
                      style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.black.withValues(alpha: 0.6))),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.7, reviewCount, isDark),
                    const SizedBox(height: 6),
                    _buildRatingBar(4, 0.2, reviewCount, isDark),
                    const SizedBox(height: 6),
                    _buildRatingBar(3, 0.07, reviewCount, isDark),
                    const SizedBox(height: 6),
                    _buildRatingBar(2, 0.02, reviewCount, isDark),
                    const SizedBox(height: 6),
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

  Widget _buildRatingBar(
      int stars, double percentage, int totalReviews, bool isDark) {
    final count = (totalReviews * percentage).round();
    return Row(
      children: [
        Text('$stars',
            style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.8))),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: Colors.amber, size: 12),
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
          width: 30,
          child: Text(count > 0 ? '$count' : '',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6)),
              textAlign: TextAlign.end),
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
