import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/color_constants.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';
import 'widgets/trip_search_bar.dart';
import 'widgets/country_cards_section.dart';
import 'widgets/suggested_trips_section.dart';
import 'widgets/home_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedNavIndex = 0;
  String _tripPrompt = '';

  // ✅ Список экранов для навигации
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen: Initializing trip planning screen...');

    // Инициализируем экраны
    _screens = [
      _buildHomeContent(), // Home tab content - теперь с трипами
      _buildExplorePlaceholder(), // Explore placeholder
      _buildTripsPlaceholder(), // Trips placeholder
      const ProfileScreen(), // Profile screen
    ];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTripSearch(String prompt) {
    print('🔍 HomeScreen: Trip search initiated: "$prompt"');
    setState(() {
      _tripPrompt = prompt;
    });

    // TODO: Здесь будет интеграция с AI для генерации плана поездки
    _generateTripPlan(prompt);
  }

  void _generateTripPlan(String prompt) {
    // TODO: Интеграция с AI API для генерации плана поездки
    print('🤖 Generating trip plan for: $prompt');

    // Показываем уведомление что план генерируется
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🤖 Generating trip plan for: "$prompt"'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Colors.white,
      body: _screens[_selectedNavIndex],
      bottomNavigationBar: HomeBottomNavigation(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          print('📱 HomeScreen: Bottom nav tapped: $index');
        },
      ),
    );
  }

  // ✅ Контент для Home tab (теперь с трипами)
  // ✅ В методе _buildHeader() исправляем SafeArea
  Widget _buildHomeContent() {
    return Column(
      children: [
        // ✅ ИСПРАВЛЕННЫЙ STICKY HEADER - убираем лишний отступ
        Container(
          color: Colors.white,
          child: SafeArea(
            // ✅ Перенесли SafeArea сюда
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                TripSearchBar(
                  onSearch: _handleTripSearch,
                  onTap: () => print('👆 Trip search tapped'),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.only(top: 4), // ✅ Уменьшили margin
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primary.withOpacity(0.3),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ SCROLLABLE CONTENT
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Заголовок секции
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 16, 20, 0), // ✅ Уменьшили верхний отступ
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select your next trip',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 6), // ✅ Уменьшили отступ
                      Text(
                        'Discover amazing destinations around the world',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Карточки стран
              const CountryCardsSection(),

              // Предложенные трипы
              const SuggestedTripsSection(),

              const SliverToBoxAdapter(
                child: SizedBox(height: 90),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ✅ HEADER с приветствием пользователя
  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final userName = user?.displayName?.isNotEmpty == true
            ? user!.displayName!.split(' ').first
            : 'Explorer';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $userName',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to Triply',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    user?.displayName?.isNotEmpty == true
                        ? user!.displayName!.substring(0, 1).toUpperCase()
                        : user?.email?.isNotEmpty == true
                            ? user!.email!.substring(0, 1).toUpperCase()
                            : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Placeholder для Explore
  Widget _buildExplorePlaceholder() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.explore_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Explore Coming Soon',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover new places and experiences.\nThis feature will be available soon!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
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

  // Placeholder для Trips
  Widget _buildTripsPlaceholder() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Text(
                    'My Trips',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.card_travel_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.card_travel_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No trips yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start planning your first trip from the Home tab!\nYour saved trips will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
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
}
