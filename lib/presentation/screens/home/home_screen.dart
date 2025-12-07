import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../../core/data/repositories/city_repository.dart';
import '../../../core/models/country_model.dart';
import '../../../providers/trip_provider.dart';
import '../profile/profile_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../my_trips/my_trips_screen.dart';
import 'date_selection_dialog.dart';
import 'theme/home_theme.dart';
import 'widgets/activity_selector.dart';
import 'widgets/home_bottom_navigation.dart';
import 'widgets/nearby_country_cards_section.dart';
import 'widgets/trips_by_city_section.dart';
import 'widgets/search/search_modal.dart';
import 'widgets/header/home_header.dart';
import 'widgets/header/safe_area_bar.dart';
import 'widgets/header/animated_gradient_header.dart';
import 'widgets/content/home_search_field.dart';
import 'widgets/content/section_header.dart';
import 'widgets/content/placeholder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;
  int _selectedNavIndex = 0;
  int _selectedActivity = -1;
  String? _selectedActivityType;
  double _scrollOpacity = 0.0;
  double _scrollOffset = 0.0;
  bool _pullToSearchTriggered = false;

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

  void _onScroll() {
    final newOpacity =
        (_scrollController.offset / HomeTheme.maxScrollForOpacity)
            .clamp(0.0, 1.0);

    if ((_scrollOpacity - newOpacity).abs() > 0.01) {
      setState(() => _scrollOpacity = newOpacity);
    }

    final newOffset = _scrollController.offset;
    if ((_scrollOffset - newOffset).abs() > 1) {
      setState(() => _scrollOffset = newOffset);
    }

    if (newOffset < 0) {
      final pullAmount = -newOffset;

      if (pullAmount >= HomeTheme.pullToSearchThreshold &&
          !_pullToSearchTriggered) {
        _pullToSearchTriggered = true;
        HapticFeedback.mediumImpact();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pullToSearchTriggered) {
            SearchModal.show(context).then((_) {
              if (mounted) {
                _pullToSearchTriggered = false;
              }
            });
          }
        });
      }
    } else if (newOffset > 10) {
      _pullToSearchTriggered = false;
    }
  }

  Future<void> _loadInitialData() async {
    final tripProvider = context.read<TripProvider>();

    await tripProvider.loadNearbyPublicTrips(
        radiusKm: HomeTheme.nearbyTripsRadius);

    if (tripProvider.nearbyTrips.isEmpty) {
      await tripProvider.loadFeaturedPublicTrips();
    }
  }

  void _onActivitySelected(int index) {
    setState(() {
      if (_selectedActivity == index) {
        _selectedActivity = -1;
        _selectedActivityType = null;
      } else {
        _selectedActivity = index;
        _selectedActivityType = HomeTheme.activityMap[index];
      }
    });
  }

  void _onNavigationTap(int index) {
    if (index == 2) {
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

    final tripProvider = context.read<TripProvider>();
    final cityTripsCount = _calculateCityTripsCount(tripProvider);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildContent(),
          if (_selectedNavIndex == 0) SafeAreaBar(opacity: _scrollOpacity),
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
      1 => const PlaceholderScreen(
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
    final isActivitySticky = _scrollOffset > HomeTheme.headerContentHeight;
    final isPullingUp = _scrollOffset < 0;

    final searchProgress = isPullingUp
        ? 0.0
        : (_scrollOffset / HomeTheme.searchScrollThreshold).clamp(0.0, 1.0);
    final searchFieldHeight =
        HomeTheme.searchFieldFullHeight * (1 - searchProgress);
    final searchFieldOpacity = (1 - searchProgress * 1.2).clamp(0.0, 1.0);

    // Single ActivitySelector widget - reused in different positions
    final activitySelector = ActivitySelector(
      selectedIndex: _selectedActivity,
      onActivitySelected: _onActivitySelected,
      isDarkMode: true,
    );

    return Stack(
      children: [
        AnimatedGradientHeader(opacity: 1 - _scrollOpacity),
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    HomeHeader(
                      onProfileTap: () =>
                          setState(() => _selectedNavIndex = 4),
                    ),
                    // Always keep the space, but hide visually when sticky
                    Opacity(
                      opacity: isActivitySticky ? 0.0 : 1.0,
                      child: activitySelector,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: searchFieldHeight,
                      child: Opacity(
                        opacity: searchFieldOpacity,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: HomeSearchField(
                            onTap: () => SearchModal.show(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: _selectedActivityType != null ? 16 : 12),
                  if (_selectedActivityType == null) ...[
                    SectionHeader(
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
        // Sticky activity selector at top
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
                  child: activitySelector,
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
