import 'package:flutter/material.dart';
import '../../../core/constants/color_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Plan Smart',
      subtitle: 'AI-Powered Trip Planning',
      description: 'Tell us your dreams, and we\'ll create the perfect itinerary just for you.',
      icon: Icons.auto_awesome,
      color: AppColors.primary,
    ),
    OnboardingData(
      title: 'Book Easy',
      subtitle: 'Best Deals in One Place',
      description: 'Compare prices from hundreds of providers to find the best hotels and flights.',
      icon: Icons.card_travel,
      color: AppColors.secondary,
    ),
    OnboardingData(
      title: 'Travel Happy',
      subtitle: 'Your Journey Begins',
      description: 'Real-time updates, offline maps, and 24/7 support throughout your adventure.',
      icon: Icons.explore,
      color: AppColors.accent,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // ← Коричневый фон как в splash
      body: SafeArea(
        child: Column(
          children: [
            
            // ========== HEADER С СТРЕЛОЧКАМИ ==========
            _buildHeader(),
            
            // ========== СЛАЙДЫ-КАРТОЧКИ ==========
            Expanded(
              flex: 6,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildSlideCard(_pages[index]);
                },
              ),
            ),
            
            // ========== ИНДИКАТОРЫ ТОЧЕК ==========
            _buildDotsIndicator(),
            
            const SizedBox(height: 40), // ← Отступ внизу
            
          ],
        ),
      ),
    );
  }
  
  // Header со стрелочками навигации
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          
          // Стрелочка назад
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
            onPressed: _currentPage > 0 ? _goToPreviousPage : null,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
          ),
          
          // Skip кнопка
          TextButton(
            onPressed: _goToRegistration,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Стрелочка вперед
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
            onPressed: _currentPage < _pages.length - 1 ? _goToNextPage : _goToRegistration,
            splashColor: Colors.white.withOpacity(0.2),
            highlightColor: Colors.white.withOpacity(0.1),
          ),
          
        ],
      ),
    );
  }
  
  // Слайд в виде карточки
  Widget _buildSlideCard(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25), // ← Скругленные углы
        ),
        elevation: 8, // ← Тень для карточки
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              // Иконка с цветным фоном
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(65),
                  border: Border.all(
                    color: data.color.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  data.icon,
                  size: 70,
                  color: data.color,
                ),
              ),
              
              const SizedBox(height: 35),
              
              // Заголовок
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Подзаголовок
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 18,
                  color: data.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Описание
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
  
  // Точки-индикаторы
  Widget _buildDotsIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _pages.asMap().entries.map((entry) {
          int index = entry.key;
          return Container(
            width: _currentPage == index ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentPage == index 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.5),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // ========== НАВИГАЦИЯ ==========
  
  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _goToRegistration() {
    // TODO: Переход к регистрации
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Переход к регистрации'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

// Модель данных для слайда
class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  
  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
