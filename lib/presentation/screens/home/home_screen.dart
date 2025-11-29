import 'dart:ui';
import 'dart:math' show sin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/models/country_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/trip_provider.dart';
import '../profile/profile_screen.dart';
import 'widgets/activity_selector.dart';
import 'widgets/home_bottom_navigation.dart';
import 'widgets/nearby_country_cards_section.dart';
import 'widgets/trips_by_city_section.dart';
import 'widgets/search_modal.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../my_trips/my_trips_screen.dart';
import 'date_selection_dialog.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ══════════════════════════════════════════════════════════════════════════
  // ✅ КОНСТАНТЫ
  // ══════════════════════════════════════════════════════════════════════════
  static const double _maxScrollForOpacity = 10.0;
  static const double _nearbyTripsRadius = 3000.0;
  static const double _searchFieldFullHeight = 36.0;
  static const double _searchScrollThreshold = 50.0;
  static const double _pullToSearchThreshold = 100.0;

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ STATE
  // ══════════════════════════════════════════════════════════════════════════
  late final ScrollController _scrollController;
  int _selectedNavIndex = 0;
  int _selectedActivity = -1;
  String? _selectedActivityType;
  double _scrollOpacity = 0.0;
  double _scrollOffset = 0.0;
  bool _pullToSearchTriggered = false;

  static const Map<int, String> _activityMap = {
    0: 'cycling',
    1: 'beach',
    2: 'skiing',
    3: 'mountains',
    4: 'hiking',
    5: 'sailing',
    6: 'desert',
    7: 'camping',
    8: 'city',
    9: 'wellness',
    10: 'road_trip',
  };

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ LIFECYCLE
  // ══════════════════════════════════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ HANDLERS
  // ══════════════════════════════════════════════════════════════════════════
  void _onScroll() {
    final newOpacity =
        (_scrollController.offset / _maxScrollForOpacity).clamp(0.0, 1.0);

    if ((_scrollOpacity - newOpacity).abs() > 0.01) {
      setState(() => _scrollOpacity = newOpacity);
    }

    final newOffset = _scrollController.offset;
    if ((_scrollOffset - newOffset).abs() > 1) {
      setState(() => _scrollOffset = newOffset);
    }

    // Pull-to-search: detect negative offset (overscroll at top)
    if (newOffset < 0) {
      final pullAmount = -newOffset;

      // Open search when threshold reached
      if (pullAmount >= _pullToSearchThreshold && !_pullToSearchTriggered) {
        _pullToSearchTriggered = true;
        HapticFeedback.mediumImpact();
        // Open search modal
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pullToSearchTriggered) {
            SearchModal.show(context).then((_) {
              // Reset flag only after modal is closed
              if (mounted) {
                _pullToSearchTriggered = false;
              }
            });
          }
        });
      }
    } else if (newOffset > 10) {
      // Only reset when scrolled down a bit, not immediately
      _pullToSearchTriggered = false;
    }
  }

  double get _pullToSearchProgress {
    if (_scrollOffset >= 0) return 0.0;
    return (-_scrollOffset / _pullToSearchThreshold).clamp(0.0, 1.5);
  }

  Future<void> _loadInitialData() async {
    final tripProvider = context.read<TripProvider>();

    print('🔄 Loading trips...');
    await tripProvider.loadNearbyPublicTrips(radiusKm: _nearbyTripsRadius);
    print('📊 Nearby trips loaded: ${tripProvider.nearbyTrips.length}');

    if (tripProvider.nearbyTrips.isEmpty) {
      print('⚠️ No nearby trips, loading featured...');
      await tripProvider.loadFeaturedPublicTrips();
      print('📊 Featured trips loaded: ${tripProvider.featuredTrips.length}');
    }
  }

  void _onActivitySelected(int index) {
    setState(() {
      if (_selectedActivity == index) {
        _selectedActivity = -1;
        _selectedActivityType = null;
      } else {
        _selectedActivity = index;
        _selectedActivityType = _activityMap[index];
      }
    });
  }

  void _onNavigationTap(int index) {
    if (index == 2) {
      // Open AI Chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AiChatScreen(),
        ),
      );
      return;
    }
    if (index == _selectedNavIndex) return;
    setState(() => _selectedNavIndex = index);
  }

  Future<void> _showAllCities() async {
    HapticFeedback.mediumImpact();

    final cityRepository = CityRepository();
    final cities = await cityRepository.getPopularCities(limit: 20);

    if (!mounted) return;

    // Get trips count from TripProvider
    final tripProvider = context.read<TripProvider>();
    final cityTripsCount = _calculateCityTripsCount(tripProvider);

    // Show bottom sheet - it will sort by location in background
    AllCitiesBottomSheet.show(
      context,
      cities: cities,
      isDarkMode: true,
      cityTripsCount: cityTripsCount,
      onCityTap: (city) {
        final countryModel = CountryModel(
          id: city.id,
          name: city.name,
          continent: city.country,
          imageUrl: city.imageUrl,
          rating: 4.5,
        );

        DateSelectionDialog.show(
          context,
          country: countryModel,
          isDarkMode: true,
          onDatesSelected: (startDate, endDate) {
            debugPrint('Selected ${city.name}: $startDate -> $endDate');
          },
        );
      },
    );
  }

  Map<String, int> _calculateCityTripsCount(TripProvider tripProvider) {
    final allTrips = <dynamic>[
      ...tripProvider.publicTrips,
      ...tripProvider.nearbyPublicTrips,
    ];

    final seenIds = <String>{};
    final uniqueTrips = allTrips.where((trip) {
      final id = trip.id as String;
      if (seenIds.contains(id)) return false;
      seenIds.add(id);
      return true;
    }).toList();

    final Map<String, int> counts = {};
    for (final trip in uniqueTrips) {
      final cityName = trip.city?.toLowerCase().trim() as String?;
      if (cityName != null && cityName.isNotEmpty) {
        counts[cityName] = (counts[cityName] ?? 0) + 1;
      }
    }
    return counts;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildContent(),
          // Only show SafeAreaBar on home screen (index 0)
          if (_selectedNavIndex == 0)
            _SafeAreaBar(opacity: _scrollOpacity),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedNavIndex != 0) {
      return _getCurrentScreen();
    }
    return _buildHomeContent();
  }

  Widget _getCurrentScreen() {
    return switch (_selectedNavIndex) {
      1 => _PlaceholderScreen(
          icon: Icons.explore_rounded,
          heading: 'Explore Coming Soon',
          description: 'Discover new places.',
        ),
      3 => const MyTripsScreen(),
      4 => const ProfileScreen(),
      _ => _buildHomeContent(),
    };
  }

  Widget _buildHomeContent() {
    // Header height (location + avatar row) = ~56px
    const headerContentHeight = 56.0;
    // Activity selector becomes sticky when scrolled down past header
    final isActivitySticky = _scrollOffset > headerContentHeight;
    // When pulling up (overscroll), keep header static
    final isPullingUp = _scrollOffset < 0;

    // Search field animation based on scroll (only when scrolling down)
    final searchProgress = isPullingUp ? 0.0 : (_scrollOffset / _searchScrollThreshold).clamp(0.0, 1.0);
    final searchFieldHeight = _searchFieldFullHeight * (1 - searchProgress);
    final searchFieldOpacity = (1 - searchProgress * 1.2).clamp(0.0, 1.0);

    return Stack(
      children: [
        _AnimatedGradientHeader(opacity: 1 - _scrollOpacity),
        // When pulling up, show static header overlay
        if (isPullingUp) ...[
          // Static header that stays in place during overscroll
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomeHeader(
                  onProfileTap: () => setState(() => _selectedNavIndex = 4),
                ),
                ActivitySelector(
                  selectedIndex: _selectedActivity,
                  onActivitySelected: _onActivitySelected,
                  isDarkMode: true,
                ),
                const SizedBox(height: 8),
                // Search field with pull-to-search effect
                Transform.translate(
                  offset: Offset(0, _pullToSearchProgress * 8),
                  child: Transform.scale(
                    scale: 1.0 + (_pullToSearchProgress * 0.03),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _HomeSearchField(
                        onTap: () => SearchModal.show(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Opacity(
                  // Hide scrolling header when showing static one
                  opacity: isPullingUp ? 0.0 : 1.0,
                  child: Column(
                    children: [
                      // Header (scrolls with content)
                      _HomeHeader(
                        onProfileTap: () => setState(() => _selectedNavIndex = 4),
                      ),
                      // Activity selector (scrolls, but has sticky overlay)
                      // Hide when sticky version is shown to prevent duplicates
                      Opacity(
                        opacity: isActivitySticky ? 0.0 : 1.0,
                        child: ActivitySelector(
                          selectedIndex: _selectedActivity,
                          onActivitySelected: _onActivitySelected,
                          isDarkMode: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Search field (collapsible)
                      SizedBox(
                        height: searchFieldHeight,
                        child: Opacity(
                          opacity: searchFieldOpacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _HomeSearchField(
                              onTap: () => SearchModal.show(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: _selectedActivityType != null ? 16 : 12),
                  // Hide nearby cities section when activity is selected
                  if (_selectedActivityType == null) ...[
                    _SectionHeader(
                      title: 'Nearby cities',
                      onViewAll: _showAllCities,
                    ),
                    _buildCountryCards(),
                    const SizedBox(height: 24),
                  ],
                  _buildSuggestedTrips(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
        // Sticky activity selector - appears at top when scrolled down
        if (isActivitySticky)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.darkBackground,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: ActivitySelector(
                    selectedIndex: _selectedActivity,
                    onActivitySelected: _onActivitySelected,
                    isDarkMode: true,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCountryCards() {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        return NearbyCountryCardsSection(
          userCountry: tripProvider.currentCountry,
          isDarkMode: true,
        );
      },
    );
  }

  Widget _buildSuggestedTrips() {
    return TripsByCitySection(
      activityType: _selectedActivityType,
      isDarkMode: true,
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        bottom: false,
        child: HomeBottomNavigation(
          currentIndex: _selectedNavIndex,
          onTap: _onNavigationTap,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ EXTRACTED WIDGETS (для уменьшения rebuilds)
// ══════════════════════════════════════════════════════════════════════════

class _SafeAreaBar extends StatelessWidget {
  final double opacity;

  const _SafeAreaBar({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          color: AppColors.darkBackground.withOpacity(opacity),
        ),
      ),
    );
  }
}

class _AnimatedGradientHeader extends StatelessWidget {
  final double opacity;

  const _AnimatedGradientHeader({required this.opacity});

  // ✅ Кешируем градиент
  static final _gradientColors = [
    const Color.fromARGB(255, 56, 22, 116).withOpacity(0.3),
    const Color.fromARGB(255, 51, 20, 103).withOpacity(0.3),
    const Color.fromARGB(255, 66, 27, 133).withOpacity(0.3),
    const Color.fromARGB(255, 78, 27, 161).withOpacity(0.25),
    const Color.fromARGB(255, 69, 23, 142).withOpacity(0.2),
    const Color.fromARGB(255, 56, 39, 2).withOpacity(0.15),
    const Color.fromARGB(255, 90, 40, 1).withOpacity(0.1),
    const Color(0xFF2E0052).withOpacity(0.07),
    const Color(0xFF1A0033).withOpacity(0.04),
    AppColors.darkBackground.withOpacity(0.02),
    AppColors.darkBackground.withOpacity(0.0),
  ];

  static const _gradientStops = [
    0.0,
    0.12,
    0.25,
    0.38,
    0.5,
    0.62,
    0.72,
    0.82,
    0.9,
    0.96,
    1.0
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        opacity: opacity,
        child: ClipPath(
          clipper: const WavyBottomClipper(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _gradientColors,
                stops: _gradientStops,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _HomeHeader({
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _LocationDisplay(),
          _ProfileAvatar(onTap: onProfileTap),
        ],
      ),
    );
  }
}

class _LocationDisplay extends StatelessWidget {
  const _LocationDisplay();

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        final country = tripProvider.currentCountry ?? 'Loading...';
        final isLoading = tripProvider.isLoadingLocation;

        return GestureDetector(
          onTap: tripProvider.refreshLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.01),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      country,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final photoUrl = authProvider.user?.avatarUrl;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _DefaultAvatar(),
                          )
                        : const _DefaultAvatar(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({
    required this.title,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String description;

  const _PlaceholderScreen({
    required this.icon,
    required this.heading,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
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

// ══════════════════════════════════════════════════════════════════════════
// ✅ HOME SEARCH FIELD
// ══════════════════════════════════════════════════════════════════════════

class _HomeSearchField extends StatelessWidget {
  final VoidCallback onTap;

  const _HomeSearchField({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.4),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Search',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// ✅ CLIPPERS (оптимизированы с shouldReclip)
// ══════════════════════════════════════════════════════════════════════════

class MainContentClipper extends CustomClipper<Path> {
  final double bottomNavHeight;

  const MainContentClipper({this.bottomNavHeight = 80.0});

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    const notchRadius = 35.0;

    path
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height - bottomNavHeight)
      ..lineTo(centerX + notchRadius + 20, height - bottomNavHeight)
      ..quadraticBezierTo(
        centerX + notchRadius,
        height - bottomNavHeight,
        centerX + notchRadius - 10,
        height - bottomNavHeight + 15,
      )
      ..quadraticBezierTo(
        centerX + 10,
        height - bottomNavHeight + 25,
        centerX,
        height - bottomNavHeight + 25,
      )
      ..quadraticBezierTo(
        centerX - 10,
        height - bottomNavHeight + 25,
        centerX - notchRadius + 10,
        height - bottomNavHeight + 15,
      )
      ..quadraticBezierTo(
        centerX - notchRadius,
        height - bottomNavHeight,
        centerX - notchRadius - 20,
        height - bottomNavHeight,
      )
      ..lineTo(0, height - bottomNavHeight)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(MainContentClipper oldClipper) =>
      bottomNavHeight != oldClipper.bottomNavHeight;
}

class WavyBottomClipper extends CustomClipper<Path> {
  const WavyBottomClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    path
      ..moveTo(0, 0)
      ..lineTo(width, 0)
      ..lineTo(width, height * 0.65);

    const waveCount = 4;
    const amplitude = 25.0;
    const pi = 3.14159;

    for (int i = 0; i <= 100; i++) {
      final x = width - (width / 100) * i;
      final normalizedX = i / 100.0;

      final wave1 = amplitude * 0.8 * sin(normalizedX * waveCount * pi);
      final wave2 = amplitude * 0.5 * sin(normalizedX * waveCount * 2 * pi);
      final wave3 = amplitude * 0.3 * sin(normalizedX * waveCount * 3 * pi);

      final y = height * 0.75 + wave1 + wave2 + wave3;
      path.lineTo(x, y);
    }

    path
      ..lineTo(0, height * 0.75)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
