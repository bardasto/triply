import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/color_constants.dart';
import '../../../home/widgets/trip_details/theme/trip_details_theme.dart';
import '../../../home/widgets/trip_details/widgets/header/blur_scroll_header.dart';
import '../../../home/widgets/trip_details/widgets/header/sheet_close_button.dart';
import '../../../home/widgets/trip_details/widgets/header/sheet_drag_handle.dart';

/// Bottom sheet for displaying place details with alternatives carousel
/// Design based on TripDetailsBottomSheet style
class PlaceDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> place;
  final List<Map<String, dynamic>> alternatives;

  const PlaceDetailsBottomSheet({
    super.key,
    required this.place,
    required this.alternatives,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> place,
    List<Map<String, dynamic>> alternatives = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceDetailsBottomSheet(
        place: place,
        alternatives: alternatives,
      ),
    );
  }

  @override
  State<PlaceDetailsBottomSheet> createState() => _PlaceDetailsBottomSheetState();
}

class _PlaceDetailsBottomSheetState extends State<PlaceDetailsBottomSheet> {
  late Map<String, dynamic> _currentPlace;
  late List<Map<String, dynamic>> _alternatives;
  late TripDetailsTheme _theme;

  // Image gallery
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Scroll controller for scrolling to top
  ScrollController? _scrollController;

  // Expandable sections
  bool _isOpeningHoursExpanded = false;
  bool _isDescriptionExpanded = false;

  final ValueNotifier<double> _scrollOffset = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _currentPlace = Map<String, dynamic>.from(widget.place);
    _alternatives = widget.alternatives.map((e) => Map<String, dynamic>.from(e)).toList();
    _theme = TripDetailsTheme.of(true); // Always dark mode
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  /// Switch to an alternative place and scroll to top
  void _switchToAlternative(Map<String, dynamic> alt, int altIndex) {
    HapticFeedback.selectionClick();

    // Save current place to put in alternatives
    final previousPlace = Map<String, dynamic>.from(_currentPlace);

    setState(() {
      // Set new current place
      _currentPlace = Map<String, dynamic>.from(alt);

      // Replace the clicked alternative with the previous main place
      _alternatives[altIndex] = previousPlace;

      // Reset image index
      _currentImageIndex = 0;

      // Reset expanded sections
      _isDescriptionExpanded = false;
      _isOpeningHoursExpanded = false;
    });

    // Reset image gallery
    _pageController.jumpToPage(0);

    // Scroll to top with animation
    _scrollController?.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  // Getters for current place data
  String get _name => _currentPlace['name'] ?? 'Unknown Place';
  String get _description => _currentPlace['description'] ?? _currentPlace['why_recommended'] ?? '';
  String get _address => _currentPlace['address'] ?? '';
  String get _city => _currentPlace['city'] ?? '';
  String get _country => _currentPlace['country'] ?? '';
  String get _placeType => _currentPlace['place_type'] ?? _currentPlace['category'] ?? 'Place';
  // Use estimated_price for real price, fallback to price_level
  String get _priceLevel {
    final estimatedPrice = _currentPlace['estimated_price'] as String? ?? '';
    return estimatedPrice.isNotEmpty ? estimatedPrice : (_currentPlace['price_level'] ?? '');
  }
  double get _rating => (_currentPlace['rating'] as num?)?.toDouble() ?? 0.0;
  int get _reviewCount => (_currentPlace['review_count'] as num?)?.toInt() ?? 0;
  String? get _website => _currentPlace['website'];
  Map<String, dynamic>? get _openingHours => _currentPlace['opening_hours'] as Map<String, dynamic>?;

  List<String> get _images {
    final images = <String>[];
    final imageUrl = _currentPlace['image_url'];
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      images.add(imageUrl.toString());
    }
    final imagesList = _currentPlace['images'] as List<dynamic>?;
    if (imagesList != null) {
      for (final img in imagesList) {
        String? url;
        if (img is String) {
          url = img;
        } else if (img is Map && img['url'] != null) {
          url = img['url'].toString();
        }
        if (url != null && url.isNotEmpty && !images.contains(url)) {
          images.add(url);
        }
      }
    }
    return images;
  }

  void _nextImage() {
    if (_currentImageIndex < _images.length - 1) {
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

  void _goToImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _isClosing = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: _handleSheetNotification,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.85,
        minChildSize: 0.0,
        expand: false,
        snap: true,
        snapSizes: const [0.85],
        builder: (context, scrollController) {
          return Container(
            decoration: _theme.sheetDecoration,
            child: Stack(
              children: [
                _buildScrollableContent(scrollController),
                // Blur header on scroll - exact same as trip_details
                ValueListenableBuilder<double>(
                  valueListenable: _scrollOffset,
                  builder: (context, offset, _) => BlurScrollHeader(
                    scrollOffset: offset,
                    isDark: true,
                  ),
                ),
                // Drag handle - exact same as trip_details
                const SheetDragHandle(),
                // Close button - exact same as trip_details
                SheetCloseButton(onClose: () => Navigator.pop(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _handleSheetNotification(DraggableScrollableNotification notification) {
    if (notification.extent <= 0.05 && !_isClosing) {
      _isClosing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
      });
    }
    return false;
  }

  Widget _buildScrollableContent(ScrollController scrollController) {
    // Save scroll controller for scrolling to top when switching alternatives
    _scrollController = scrollController;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(TripDetailsTheme.radiusSheet),
        topRight: Radius.circular(TripDetailsTheme.radiusSheet),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification &&
              notification.metrics.axis == Axis.vertical) {
            _scrollOffset.value = notification.metrics.pixels;
          }
          return false;
        },
        child: CustomScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildImageGallery()),
            SliverToBoxAdapter(child: _buildThumbnailList()),
            SliverToBoxAdapter(child: _buildContentSections()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _images;

    return SizedBox(
      height: 360,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Images
          if (images.isEmpty)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: Center(
                child: Icon(
                  _getPlaceTypeIcon(_placeType),
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemCount: images.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTapUp: (details) {
                    final width = MediaQuery.of(context).size.width;
                    if (details.localPosition.dx < width / 2) {
                      _prevImage();
                    } else {
                      _nextImage();
                    }
                  },
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (c, e, s) => Container(
                      color: AppColors.primary,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 54, color: Colors.white38),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Bottom gradient
          if (images.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _theme.overlayLight,
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bar indicators
          if (images.length > 1)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: List.generate(images.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: index == _currentImageIndex
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
    );
  }

  Widget _buildThumbnailList() {
    final images = _images;
    if (images.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 20),
        itemCount: images.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final isSelected = index == _currentImageIndex;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _goToImage(index);
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TripDetailsTheme.radiusSmall),
                color: _theme.surfaceColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.5,
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildHeader(),
        Divider(height: 1, color: _theme.dividerColor),
        if (_description.isNotEmpty) ...[
          _buildDescriptionSection(),
        ],
        const SizedBox(height: 16),
        _buildInfoBlock(),
        if (_rating > 0) ...[
          const SizedBox(height: 24),
          _buildReviewsSection(),
        ],
        // Alternatives section at bottom
        if (_alternatives.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAlternativesSection(),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _name,
                  style: _theme.titleLarge,
                  maxLines: 2,
                ),
              ),
              if (_rating > 0) ...[
                const SizedBox(width: 12),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          // Category & Price
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPlaceTypeIcon(_placeType),
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatPlaceType(_placeType),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_priceLevel.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  _priceLevel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    const int trimLength = 150;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: _theme.titleSmall),
          const SizedBox(height: 12),
          _buildExpandableDescription(trimLength),
        ],
      ),
    );
  }

  Widget _buildExpandableDescription(int trimLength) {
    if (_description.length <= trimLength) {
      return Text(_description, style: _theme.bodyMedium);
    }

    final trimmedText = _trimToLastWord(_description, trimLength);

    return Text.rich(
      TextSpan(
        style: _theme.bodyMedium,
        children: [
          TextSpan(
            text: _isDescriptionExpanded ? _description : '$trimmedText... ',
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
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _trimToLastWord(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final trimmed = text.substring(0, maxLength);
    final lastSpace = trimmed.lastIndexOf(' ');
    if (lastSpace > 0) {
      return trimmed.substring(0, lastSpace);
    }
    return trimmed;
  }

  Widget _buildInfoBlock() {
    final hasAddress = _address.isNotEmpty;
    final hasWebsite = _website != null && _website!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildInfoItem(
            child: _buildOpeningHoursSection(),
            isFirst: true,
            isLast: !hasAddress && !hasWebsite,
          ),
          if (hasAddress) ...[
            const SizedBox(height: 10),
            _buildInfoItem(
              child: _buildAddressSection(),
              isFirst: false,
              isLast: !hasWebsite,
            ),
          ],
          if (hasWebsite) ...[
            const SizedBox(height: 10),
            _buildInfoItem(
              child: _buildWebsiteSection(),
              isFirst: false,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required Widget child,
    required bool isFirst,
    required bool isLast,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _theme.surfaceColor,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : const Radius.circular(4),
          bottom: isLast ? const Radius.circular(20) : const Radius.circular(4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildOpeningHoursSection() {
    final openingStatus = _getOpeningStatus(_openingHours);
    final weekdayHours = _getWeekdayHours(_openingHours);
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
      iconColor = _theme.textSecondary;
      textColor = _theme.textPrimary;
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
                    color: _theme.textSecondary,
                    size: 20,
                  ),
              ],
            ),
            if (_isOpeningHoursExpanded && hasHours) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: _theme.dividerColor),
              const SizedBox(height: 12),
              ...weekdayHours.map((dayHours) {
                final parts = dayHours.split(':');
                final day = parts[0].trim();
                final hours = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(day, style: _theme.bodySmall.copyWith(color: _theme.textPrimary)),
                      Text(hours, style: _theme.bodySmall),
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

  Widget _buildAddressSection() {
    final fullAddress = _city.isNotEmpty || _country.isNotEmpty
        ? '$_address, $_city, $_country'
        : _address;

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
              child: Text(
                fullAddress,
                style: TextStyle(
                  fontSize: 16,
                  color: _theme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _theme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebsiteSection() {
    String displayUrl = _website!;
    try {
      final uri = Uri.parse(_website!);
      displayUrl = uri.host.replaceAll('www.', '');
    } catch (_) {}

    return GestureDetector(
      onTap: () => _openWebsite(_website),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.language, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayUrl,
                style: TextStyle(
                  fontSize: 16,
                  color: _theme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: _theme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ratings & reviews', style: _theme.titleSmall),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _theme.surfaceColor,
              borderRadius: BorderRadius.circular(TripDetailsTheme.radiusLarge),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      _rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < _rating.floor()
                              ? Icons.star
                              : (index < _rating ? Icons.star_half : Icons.star_border),
                          color: Colors.amber,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_reviewCount reviews',
                      style: _theme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, 0.7),
                      const SizedBox(height: 6),
                      _buildRatingBar(4, 0.2),
                      const SizedBox(height: 6),
                      _buildRatingBar(3, 0.07),
                      const SizedBox(height: 6),
                      _buildRatingBar(2, 0.02),
                      const SizedBox(height: 6),
                      _buildRatingBar(1, 0.01),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    final count = (_reviewCount * percentage).round();
    return Row(
      children: [
        Text('$stars', style: _theme.labelMedium),
        const SizedBox(width: 4),
        const Icon(Icons.star, color: Colors.amber, size: 12),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: _theme.dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            count > 0 ? '$count' : '',
            style: _theme.labelMedium,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Similar places', style: _theme.titleSmall),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _alternatives.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final alt = _alternatives[index];
              return _buildAlternativeCard(alt, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlternativeCard(Map<String, dynamic> alt, int index) {
    final name = alt['name'] as String? ?? 'Unknown';
    final imageUrl = alt['image_url'] as String?;
    final rating = (alt['rating'] as num?)?.toDouble() ?? 0.0;
    // Use estimated_price for real price, fallback to price_level
    final estimatedPrice = alt['estimated_price'] as String? ?? '';
    final priceLevel = estimatedPrice.isNotEmpty ? estimatedPrice : (alt['price_level'] as String? ?? '');
    final placeType = alt['place_type'] as String? ?? alt['category'] as String? ?? 'place';

    return GestureDetector(
      onTap: () => _switchToAlternative(alt, index),
      child: Container(
        width: 160,
        margin: EdgeInsets.only(right: index < _alternatives.length - 1 ? 12 : 0),
        decoration: BoxDecoration(
          color: _theme.cardColor,
          borderRadius: BorderRadius.circular(TripDetailsTheme.radiusMedium),
          border: Border.all(color: _theme.borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(placeType),
                    )
                  else
                    _buildPlaceholder(placeType),
                  // Rating badge
                  if (rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _theme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Type & Price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _theme.surfaceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatPlaceType(placeType),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _theme.textSecondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (priceLevel.isNotEmpty)
                          Flexible(
                            child: Text(
                              priceLevel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String placeType) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Center(
        child: Icon(
          _getPlaceTypeIcon(placeType),
          size: 32,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  // Helper methods
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

  String _formatPlaceType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  IconData _getPlaceTypeIcon(String placeType) {
    switch (placeType.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'bar':
        return Icons.local_bar;
      case 'hotel':
        return Icons.hotel;
      case 'museum':
        return Icons.museum;
      case 'park':
        return Icons.park;
      case 'attraction':
        return Icons.attractions;
      case 'shop':
        return Icons.shopping_bag;
      case 'nightclub':
        return Icons.nightlife;
      case 'spa':
        return Icons.spa;
      case 'beach':
        return Icons.beach_access;
      case 'viewpoint':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }

  void _showAddressOptions(BuildContext context) {
    final double lat = (_currentPlace['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lng = (_currentPlace['longitude'] as num?)?.toDouble() ?? 0.0;

    HapticFeedback.mediumImpact();

    showCupertinoModalPopup<void>(
      context: context,
      barrierColor: Colors.transparent,
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      builder: (BuildContext context) => CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoActionSheet(
          actions: <Widget>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _copyAddress(_address);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_on_doc, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 12),
                  Text('Copy address', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17)),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _openInMaps(lat, lng);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.map, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 12),
                  Text('Open in Maps', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 17)),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text('Cancel'),
          ),
        ),
      ),
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

  Future<void> _openInMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWebsite(String? website) async {
    if (website == null || website.isEmpty) return;
    final url = Uri.parse(website);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
