import 'package:flutter/material.dart';
import '../../../../core/constants/color_constants.dart';
import 'date_selection_dialog.dart';

class CountryCardsSection extends StatefulWidget {
  const CountryCardsSection({Key? key}) : super(key: key);

  @override
  State<CountryCardsSection> createState() => _CountryCardsSectionState();
}

class _CountryCardsSectionState extends State<CountryCardsSection> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  int _selectedContinentIndex = 0; // ✅ Индекс выбранного континента

  // ✅ ПОЛНАЯ КАРТА СТРАН ПО КОНТИНЕНТАМ
  final Map<String, List<Map<String, dynamic>>> _continentCountries = {
    'Asia': [
      {
        'name': 'Japan',
        'city': 'Tokyo',
        'rating': 4.7,
        'reviews': 324,
        'image':
            'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800',
        'gradient': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      },
      {
        'name': 'Thailand',
        'city': 'Bangkok',
        'rating': 4.5,
        'reviews': 298,
        'image':
            'https://images.unsplash.com/photo-1552832230-c0197047daf9?w=800',
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      },
      {
        'name': 'Singapore',
        'city': 'Singapore',
        'rating': 4.8,
        'reviews': 156,
        'image':
            'https://images.unsplash.com/photo-1555993539-1732b0258235?w=800',
        'gradient': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      },
    ],
    'Europe': [
      {
        'name': 'Italy',
        'city': 'Rome',
        'rating': 4.8,
        'reviews': 267,
        'image':
            'https://images.unsplash.com/photo-1552832230-c0197047daf9?w=800',
        'gradient': [const Color(0xFFFF8A80), const Color(0xFFFF5722)],
      },
      {
        'name': 'France',
        'city': 'Paris',
        'rating': 4.9,
        'reviews': 189,
        'image':
            'https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=800',
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      },
      {
        'name': 'Greece',
        'city': 'Santorini',
        'rating': 4.6,
        'reviews': 156,
        'image':
            'https://images.unsplash.com/photo-1570077188670-e3a8d69ac5ff?w=800',
        'gradient': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      },
    ],
    'South America': [
      {
        'name': 'Brazil',
        'city': 'Rio de Janeiro',
        'rating': 5.0,
        'reviews': 143,
        'image':
            'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800',
        'gradient': [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
      },
      {
        'name': 'Argentina',
        'city': 'Buenos Aires',
        'rating': 4.7,
        'reviews': 201,
        'image':
            'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800',
        'gradient': [const Color(0xFF667db6), const Color(0xFF0082c8)],
      },
      {
        'name': 'Peru',
        'city': 'Machu Picchu',
        'rating': 4.9,
        'reviews': 324,
        'image':
            'https://images.unsplash.com/photo-1587595431973-160d0d94add1?w=800',
        'gradient': [const Color(0xFFFFB75E), const Color(0xFFED8F03)],
      },
    ],
    'North America': [
      {
        'name': 'USA',
        'city': 'New York',
        'rating': 4.6,
        'reviews': 512,
        'image':
            'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=800',
        'gradient': [const Color(0xFF667db6), const Color(0xFF0082c8)],
      },
      {
        'name': 'Canada',
        'city': 'Toronto',
        'rating': 4.7,
        'reviews': 298,
        'image':
            'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=800',
        'gradient': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      },
      {
        'name': 'Mexico',
        'city': 'Cancun',
        'rating': 4.5,
        'reviews': 234,
        'image':
            'https://images.unsplash.com/photo-1518638150340-f706e86654de?w=800',
        'gradient': [const Color(0xFFFF8A80), const Color(0xFFFF5722)],
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ✅ ПОЛУЧИТЬ ТЕКУЩИЕ СТРАНЫ ДЛЯ ВЫБРАННОГО КОНТИНЕНТА
  List<Map<String, dynamic>> get _currentCountries {
    final continentNames = _continentCountries.keys.toList();
    final selectedContinent = continentNames[_selectedContinentIndex];
    return _continentCountries[selectedContinent] ?? [];
  }

  void _showDateSelection(Map<String, dynamic> country) {
    DateSelectionDialog.show(
      context,
      country: country['name'],
      city: country['city'],
      onDatesSelected: (startDate, endDate) {
        print(
            '📅 Selected dates: $startDate - $endDate for ${country['name']}');
        // TODO: Navigate to trip planning
        _openTripPlan(country, startDate, endDate);
      },
    );
  }

  void _openTripPlan(
      Map<String, dynamic> country, DateTime startDate, DateTime endDate) {
    // TODO: Implement trip planning navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating AI trip plan for ${country['name']} from ${_formatDate(startDate)} to ${_formatDate(endDate)}',
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ✅ ПЕРЕКЛЮЧЕНИЕ КОНТИНЕНТА
  void _selectContinent(int index) {
    setState(() {
      _selectedContinentIndex = index;
      _currentPage = 0; // Сброс на первую страну
    });

    // Анимированный переход к первой карточке
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // ✅ ПЕРЕКЛЮЧАТЕЛЬ КОНТИНЕНТОВ В ОДНУ СТРОКУ
          _buildContinentSelector(),

          const SizedBox(height: 20),

          // ✅ КАРТОЧКИ СТРАН
          SizedBox(
            height: 420,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _currentCountries.length,
              itemBuilder: (context, index) {
                final country = _currentCountries[index];
                return _buildCountryCard(country, index);
              },
            ),
          ),

          const SizedBox(height: 20),

          // ✅ ИНДИКАТОРЫ СТРАНИЦ
          _buildPageIndicators(),
        ],
      ),
    );
  }

  // ✅ СЕЛЕКТОР КОНТИНЕНТОВ В ОДНУ СТРОКУ С ГОРИЗОНТАЛЬНОЙ ПРОКРУТКОЙ
  Widget _buildContinentSelector() {
    final continents = _continentCountries.keys.toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40, // ✅ ФИКСИРОВАННАЯ ВЫСОТА
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: continents.asMap().entries.map((entry) {
            final index = entry.key;
            final continent = entry.value;
            final isSelected = index == _selectedContinentIndex;

            return Padding(
              padding: EdgeInsets.only(
                right: index < continents.length - 1
                    ? 8
                    : 0, // ✅ Отступ между кнопками
              ),
              child: GestureDetector(
                onTap: () => _selectContinent(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  height: 40, // ✅ ФИКСИРОВАННАЯ ВЫСОТА
                  constraints: const BoxConstraints(
                    minWidth: 80, // ✅ Минимальная ширина
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, // ✅ Горизонтальные отступы
                    vertical: 8, // ✅ Вертикальные отступы
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 14, // ✅ Чуть больше шрифт
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                      child: Text(
                        continent,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ✅ КАРТОЧКА СТРАНЫ
  Widget _buildCountryCard(Map<String, dynamic> country, int index) {
    final isActive = _currentPage == index;

    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isActive ? 1.0 : 0.95,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: () {
            print('🏛️ Country tapped: ${country['name']}');
            _showDateSelection(country);
          },
          child: Container(
            width: double.infinity,
            height: 420,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isActive ? 0.15 : 0.1),
                  blurRadius: isActive ? 20 : 10,
                  offset: Offset(0, isActive ? 10 : 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // ✅ ФОНОВОЕ ИЗОБРАЖЕНИЕ
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: country['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Image.network(
                      country['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: country['gradient'] as List<Color>,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.landscape_rounded,
                              size: 60,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ✅ ГРАДИЕНТ ОВЕРЛЕЙ
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black26,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // ✅ КОНТЕНТ
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // ✅ ИКОНКА ИЗБРАННОГО
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // ✅ ИНФОРМАЦИЯ О СТРАНЕ
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    country['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              Text(
                                country['city'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    country['rating'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${country['reviews']} reviews',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ✅ КНОПКА
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showDateSelection(country),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'See more',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }

  // ✅ ИНДИКАТОРЫ СТРАНИЦ
  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _currentCountries.asMap().entries.map((entry) {
        final isActive = entry.key == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }
}
