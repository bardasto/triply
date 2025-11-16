import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';

class TripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> trip;

  const TripDetailsScreen({Key? key, required this.trip}) : super(key: key);

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ✅ APP BAR С ИЗОБРАЖЕНИЕМ
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, color: Colors.white),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.trip['hero_image_url'] ?? widget.trip['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                    ),
                  ),
                  Container(
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
                ],
              ),
            ),
          ),

          // ✅ КОНТЕНТ
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════════════════
                  // ЗАГОЛОВОК
                  // ═══════════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trip['title'] ?? 'Untitled Trip',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 18, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.trip['city'] ?? ''}, ${widget.trip['country'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              widget.trip['duration'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.star,
                                size: 18, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.trip['rating'] ?? 4.5} (${widget.trip['reviews'] ?? 0} reviews)',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // ═══════════════════════════════════════════════════════
                  // ОПИСАНИЕ
                  // ═══════════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About this trip',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.trip['description'] ?? 'No description available.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // ═══════════════════════════════════════════════════════
                  // TAB BAR - Itinerary & Restaurants
                  // ═══════════════════════════════════════════════════════
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: const [
                        Tab(text: 'Itinerary'),
                        Tab(text: 'Restaurants'),
                      ],
                    ),
                  ),

                  // ═══════════════════════════════════════════════════════
                  // TAB BAR VIEW - Content for each tab
                  // ═══════════════════════════════════════════════════════
                  SizedBox(
                    height: 600, // Fixed height for TabBarView
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildItineraryTab(),
                        _buildRestaurantsTab(),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // ═══════════════════════════════════════════════════════
                  // HIGHLIGHTS
                  // ═══════════════════════════════════════════════════════
                  if (widget.trip['highlights'] != null &&
                      (widget.trip['highlights'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trip Highlights',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            (widget.trip['highlights'] as List).length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.trip['highlights'][index],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.text,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 1),

                  // ═══════════════════════════════════════════════════════
                  // ЧТО ВКЛЮЧЕНО
                  // ═══════════════════════════════════════════════════════
                  if (widget.trip['includes'] != null &&
                      (widget.trip['includes'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What\'s included',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            (widget.trip['includes'] as List).length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.trip['includes'][index],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ✅ КНОПКА БРОНИРОВАНИЯ ВНИЗУ
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    widget.trip['price'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Booking functionality coming soon!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ITINERARY TAB - Only Places (attractions, museums, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildItineraryTab() {
    if (widget.trip['itinerary'] == null ||
        (widget.trip['itinerary'] as List).isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No itinerary available',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Day-by-Day Places',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            (widget.trip['itinerary'] as List).length,
            (index) {
              final day = (widget.trip['itinerary'] as List)[index];

              // Filter only places (not restaurants)
              List<dynamic>? places = day['places'];
              List<dynamic>? filteredPlaces = places
                  ?.where((place) =>
                      place['category'] != 'breakfast' &&
                      place['category'] != 'lunch' &&
                      place['category'] != 'dinner')
                  .toList();

              if (filteredPlaces == null || filteredPlaces.isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildItineraryDayWithPlaces(
                context,
                dayNumber: day['day'] ?? index + 1,
                title: day['title'] ?? 'Day ${index + 1}',
                places: filteredPlaces,
                isLast: index == (widget.trip['itinerary'] as List).length - 1,
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESTAURANTS TAB - Breakfast, Lunch, Dinner
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRestaurantsTab() {
    // Mock restaurant data
    final mockRestaurants = {
      'breakfast': [
        {
          'name': 'Café de Flore',
          'cuisine': 'French',
          'rating': 4.5,
          'price': '€€',
          'address': '172 Boulevard Saint-Germain',
          'description': 'Iconic Parisian café, perfect for breakfast',
          'imageUrl': 'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c',
        },
        {
          'name': 'Holybelly',
          'cuisine': 'Brunch',
          'rating': 4.7,
          'price': '€€',
          'address': '19 Rue Lucien Sampaix',
          'description': 'Amazing pancakes and eggs',
          'imageUrl': 'https://images.unsplash.com/photo-1533777857889-4be7c70b33f7',
        },
      ],
      'lunch': [
        {
          'name': 'L\'Ami Jean',
          'cuisine': 'Basque',
          'rating': 4.6,
          'price': '€€€',
          'address': '27 Rue Malar',
          'description': 'Traditional Basque cuisine',
          'imageUrl': 'https://images.unsplash.com/photo-1559339352-11d035aa65de',
        },
        {
          'name': 'Frenchie',
          'cuisine': 'Modern French',
          'rating': 4.8,
          'price': '€€€',
          'address': '5 Rue du Nil',
          'description': 'Creative modern French dishes',
          'imageUrl': 'https://images.unsplash.com/photo-1559339352-11d035aa65de',
        },
      ],
      'dinner': [
        {
          'name': 'Le Comptoir du Relais',
          'cuisine': 'Bistro',
          'rating': 4.5,
          'price': '€€€',
          'address': '9 Carrefour de l\'Odéon',
          'description': 'Classic French bistro',
          'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
        },
        {
          'name': 'Septime',
          'cuisine': 'Contemporary',
          'rating': 4.9,
          'price': '€€€€',
          'address': '80 Rue de Charonne',
          'description': 'Michelin-starred contemporary cuisine',
          'imageUrl': 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0',
        },
      ],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestaurantSection('Breakfast', mockRestaurants['breakfast']!),
          const SizedBox(height: 24),
          _buildRestaurantSection('Lunch', mockRestaurants['lunch']!),
          const SizedBox(height: 24),
          _buildRestaurantSection('Dinner', mockRestaurants['dinner']!),
        ],
      ),
    );
  }

  Widget _buildRestaurantSection(String title, List<dynamic> restaurants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              title == 'Breakfast'
                  ? Icons.free_breakfast
                  : title == 'Lunch'
                      ? Icons.lunch_dining
                      : Icons.dinner_dining,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...restaurants.map((restaurant) => _buildRestaurantCard(restaurant)),
      ],
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Restaurant image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Image.network(
              restaurant['imageUrl'] ?? '',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: AppColors.background,
                child: const Icon(Icons.restaurant, color: AppColors.textSecondary),
              ),
            ),
          ),
          // Restaurant info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${restaurant['cuisine']} • ${restaurant['price']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant['rating']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.text,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ITINERARY DAY WITH PLACES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildItineraryDayWithPlaces(
    BuildContext context, {
    required int dayNumber,
    required String title,
    required List<dynamic> places,
    required bool isLast,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day indicator with line
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 120,
                  color: AppColors.primary.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Day content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),

                // Places list
                ...places.map((place) => _buildPlaceCard(place)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  place['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            place['description'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${place['duration_minutes'] ?? 60} min',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                '${place['rating'] ?? 4.0}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
