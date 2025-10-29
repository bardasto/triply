import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/models/country_model.dart';
import '../../../../core/data/repositories/trip_repository.dart';
import '../../../../providers/trip_provider.dart';
import '../date_selection_dialog.dart';

class NearbyCountryCardsSection extends StatefulWidget {
  final String? userCountry;
  final bool isDarkMode;

  const NearbyCountryCardsSection({
    super.key,
    this.userCountry,
    required this.isDarkMode,
  });

  @override
  State<NearbyCountryCardsSection> createState() =>
      _NearbyCountryCardsSectionState();
}

class _NearbyCountryCardsSectionState extends State<NearbyCountryCardsSection>
    with TickerProviderStateMixin {
  // ══════════════════════════════════════════════════════════════════════════
  // ✅ КОНСТАНТЫ
  // ══════════════════════════════════════════════════════════════════════════
  static const int _initialIndex = 10000;
  static const Duration _animationDuration = Duration(milliseconds: 350);
  static const Duration _sideCardsAnimationDuration =
      Duration(milliseconds: 60);
  static const double _swipeThresholdRatio = 0.3;
  static const double _velocityThreshold = 300.0;
  static const double _cardWidthRatio = 0.75;
  static const double _cardHeight = 450.0;
  static const int _maxNearbyCountries = 20;

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ STATE
  // ══════════════════════════════════════════════════════════════════════════
  int _currentIndex = _initialIndex;
  double _dragOffset = 0.0;
  List<CountryModel> _countries = [];
  bool _isLoading = true;

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ ANIMATIONS
  // ══════════════════════════════════════════════════════════════════════════
  late final AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late final AnimationController _sideCardsController;
  late final Animation<double> _sideCardsAnimation;

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNearbyCountries();
  }

  @override
  void didUpdateWidget(NearbyCountryCardsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userCountry != widget.userCountry) {
      _resetCards();
      _loadNearbyCountries();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sideCardsController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _sideCardsController = AnimationController(
      vsync: this,
      duration: _sideCardsAnimationDuration,
    );

    _sideCardsAnimation = CurvedAnimation(
      parent: _sideCardsController,
      curve: Curves.easeOutCubic,
    );

    _sideCardsController.forward();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ DATA LOADING
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _loadNearbyCountries() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final tripProvider = context.read<TripProvider>();
      final userPosition = tripProvider.userPosition;
      final tripRepository = TripRepository();
      final allCountries = await tripRepository.getAllCountries();

      if (userPosition == null) {
        _setCountries(allCountries.take(_maxNearbyCountries).toList());
        return;
      }

      final sortedCountries = _getSortedCountriesByDistance(
        allCountries,
        userPosition.latitude,
        userPosition.longitude,
      );

      _setCountries(sortedCountries);
    } catch (e) {
      debugPrint('❌ Error loading nearby countries: $e');
      _setCountries([]);
    }
  }

  List<CountryModel> _getSortedCountriesByDistance(
    List<CountryModel> countries,
    double userLat,
    double userLon,
  ) {
    final countriesWithDistance = countries
        .where((c) => c.latitude != null && c.longitude != null)
        .map((country) {
      final distance = _calculateDistance(
        userLat,
        userLon,
        country.latitude!,
        country.longitude!,
      );
      return _CountryWithDistance(country, distance);
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    return countriesWithDistance
        .take(_maxNearbyCountries)
        .map((item) => item.country)
        .toList();
  }

  void _setCountries(List<CountryModel> countries) {
    if (mounted) {
      setState(() {
        _countries = countries;
        _isLoading = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ CALCULATIONS
  // ══════════════════════════════════════════════════════════════════════════
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // PI / 180
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R * asin
  }

  double _calculateSwipeProgress(double screenWidth) {
    final rawProgress =
        (_dragOffset.abs() / (screenWidth * 0.8)).clamp(0.0, 1.0);
    return Curves.easeOutQuart.transform(Curves.easeOut.transform(rawProgress));
  }

  double _calculateCardScale(double swipeProgress) =>
      0.88 + (0.12 * swipeProgress); // 0.88 → 1.0

  double _calculateVerticalOffset(double swipeProgress) =>
      30.0 * (1.0 - swipeProgress);

  double _calculateHorizontalOffset(double swipeProgress) =>
      50.0 * (1.0 - swipeProgress);

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ GESTURE HANDLING
  // ══════════════════════════════════════════════════════════════════════════
  void _resetCards() {
    setState(() {
      _currentIndex = _initialIndex;
      _dragOffset = 0.0;
    });
    _sideCardsController.forward(from: 0);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _offsetAnimation = Tween<Offset>(
        begin: _offsetAnimation.value,
        end: _offsetAnimation.value + Offset(details.delta.dx, 0),
      ).animate(_animationController);
      _animationController.value = 1.0;
    });
  }

  void _onPanEnd(DragEndDetails details, double screenWidth) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final swipeThreshold = screenWidth * _swipeThresholdRatio;
    final shouldSwipe = velocity.abs() > _velocityThreshold ||
        _offsetAnimation.value.dx.abs() > swipeThreshold;

    if (shouldSwipe) {
      final isRight =
          _offsetAnimation.value.dx > 0 || velocity > _velocityThreshold;
      _performSwipe(screenWidth, isRight: isRight);
    } else {
      _animationController.reverse().then((_) {
        setState(() => _dragOffset = 0.0);
      });
    }
  }

  void _performSwipe(double screenWidth, {required bool isRight}) {
    final direction = isRight ? 1.5 : -1.5;

    _offsetAnimation = Tween<Offset>(
      begin: _offsetAnimation.value,
      end: Offset(screenWidth * direction, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0).then((_) {
      setState(() {
        _currentIndex += isRight ? 1 : -1;
        _dragOffset = 0.0;
        _animationController.reset();
        _offsetAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: Offset.zero,
        ).animate(_animationController);
      });
      _sideCardsController.forward(from: 0);
    });
  }

  void _onCardTap(CountryModel country) {
    if (_dragOffset.abs() < 5) {
      DateSelectionDialog.show(
        context,
        country: country,
        isDarkMode: widget.isDarkMode,
        onDatesSelected: (startDate, endDate) {
          debugPrint('📅 ${country.name}: $startDate → $endDate');
        },
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingState(height: _cardHeight);
    }

    if (_countries.isEmpty) {
      return const _EmptyState(height: _cardHeight);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * _cardWidthRatio;

    return SizedBox(
      height: _cardHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ..._buildBackgroundCards(screenWidth, cardWidth),
          _buildMainCard(screenWidth, cardWidth),
        ],
      ),
    );
  }

  List<Widget> _buildBackgroundCards(double screenWidth, double cardWidth) {
    final isSwipingRight = _dragOffset > 0;
    final isSwipingLeft = _dragOffset < 0;

    return [
      if (isSwipingRight)
        _buildStackedCard(
          (_currentIndex - 1) % _countries.length,
          position: -1,
          screenWidth: screenWidth,
          cardWidth: cardWidth,
        ),
      if (isSwipingLeft)
        _buildStackedCard(
          (_currentIndex + 1) % _countries.length,
          position: 1,
          screenWidth: screenWidth,
          cardWidth: cardWidth,
        ),
      if (_dragOffset == 0.0) ...[
        _buildStackedCard(
          (_currentIndex - 1) % _countries.length,
          position: -1,
          screenWidth: screenWidth,
          cardWidth: cardWidth,
        ),
        _buildStackedCard(
          (_currentIndex + 1) % _countries.length,
          position: 1,
          screenWidth: screenWidth,
          cardWidth: cardWidth,
        ),
      ],
    ];
  }

  Widget _buildMainCard(double screenWidth, double cardWidth) {
    final currentCountry = _countries[_currentIndex % _countries.length];

    return GestureDetector(
      onTap: () => _onCardTap(currentCountry),
      onPanUpdate: _onPanUpdate,
      onPanEnd: (details) => _onPanEnd(details, screenWidth),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: _offsetAnimation.value,
            child: Transform.rotate(
              angle: _offsetAnimation.value.dx / 1000,
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: cardWidth,
          height: _cardHeight,
          child: _CountryCard(country: currentCountry),
        ),
      ),
    );
  }

  Widget _buildStackedCard(
    int index, {
    required int position,
    required double screenWidth,
    required double cardWidth,
  }) {
    final country = _countries[index];
    final swipeProgress = _calculateSwipeProgress(screenWidth);
    final cardScale = _calculateCardScale(swipeProgress);
    final verticalOffset = _calculateVerticalOffset(swipeProgress);
    final horizontalOffset = _calculateHorizontalOffset(swipeProgress);

    return AnimatedBuilder(
      animation: _sideCardsAnimation,
      builder: (context, child) {
        final finalScale = cardScale * (0.7 + 0.3 * _sideCardsAnimation.value);

        return Positioned(
          top: verticalOffset,
          left: position == -1 ? horizontalOffset : null,
          right: position == 1 ? horizontalOffset : null,
          child: Opacity(
            opacity: _sideCardsAnimation.value,
            child: Transform.scale(
              scale: finalScale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: cardWidth,
                height: _cardHeight,
                child: _CountryCard(country: country),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ HELPER CLASSES
// ══════════════════════════════════════════════════════════════════════════
class _CountryWithDistance {
  final CountryModel country;
  final double distance;

  const _CountryWithDistance(this.country, this.distance);
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ EXTRACTED WIDGETS
// ══════════════════════════════════════════════════════════════════════════
class _LoadingState extends StatelessWidget {
  final double height;

  const _LoadingState({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double height;

  const _EmptyState({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No nearby countries found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  final CountryModel country;

  const _CountryCard({required this.country});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            _CardImage(imageUrl: country.imageUrl ?? ''),
            const _CardGradient(),
            const _PopularBadge(),
            const _FavoriteButton(),
            _CardInfo(country: country),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;

  const _CardImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.network(
        imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/800',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardGradient extends StatelessWidget {
  const _CardGradient();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Popular Place',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  final CountryModel country;

  const _CardInfo({required this.country});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _CountryHeader(
                  name: country.name,
                  flagEmoji: country.flagEmoji,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                        child: _LocationChip(continent: country.continent)),
                    const SizedBox(width: 8),
                    _RatingChip(rating: country.rating),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryHeader extends StatelessWidget {
  final String name;
  final String? flagEmoji;

  const _CountryHeader({
    required this.name,
    this.flagEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (flagEmoji != null) ...[
          Text(
            flagEmoji!,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LocationChip extends StatelessWidget {
  final String continent;

  const _LocationChip({required this.continent});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  continent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;

  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
