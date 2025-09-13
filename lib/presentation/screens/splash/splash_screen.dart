import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/color_constants.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // 🎯 КОНТРОЛЛЕРЫ АНИМАЦИИ
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _loadingController;

  // Анимации
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startLoadingSequence();
  }

  void _initAnimations() {
    // 🎯 ПУЛЬСИРОВАНИЕ ЛОГОТИПА
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500), // ← Скорость пульсирования
      vsync: this,
    )..repeat(reverse: true); // Бесконечное повторение туда-обратно

    // Появление элементов
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Индикатор загрузки
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 🎯 НАСТРОЙКИ ПУЛЬСИРОВАНИЯ
    _pulseAnimation = Tween<double>(
      begin: 0.95, // ← Минимальный размер (95% от оригинала)
      end: 1.05,   // ← Максимальный размер (105% от оригинала)
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut, // ← Плавная кривая пульсирования
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );
  }

  void _startLoadingSequence() async {
    // Запускаем появление логотипа
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Запускаем индикатор загрузки
    _loadingController.forward();

    // 🎯 ВРЕМЯ ПОКАЗА SPLASH SCREEN
    await Future.delayed(const Duration(milliseconds: 3500)); // ← Общее время показа

    // // Переход на следующий экран
    // if (mounted) {
    //   _navigateToNext();
    // }
  }

  void _navigateToNext() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Ваш коричневый фон
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              // 🎯 ПУЛЬСИРУЮЩИЙ ЛОГОТИП
              FadeTransition(
                opacity: _fadeAnimation,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      
                        child: Image.asset(
                          'assets/images/logonobg.png', // ← Путь к вашему логотипу
                          width: 200,  // ← Размер логотипа
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                     
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // 🎯 НАЗВАНИЕ ПРИЛОЖЕНИЯ
              

              const SizedBox(height: 10),

              

              // 🎯 АНИМИРОВАННЫЙ ИНДИКАТОР ЗАГРУЗКИ
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: AnimatedBuilder(
                        animation: _loadingController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _loadingController.value * 2 * math.pi,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                   
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Дополнительная информация
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'AI • Hotels • Routes • Adventures',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                    
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
