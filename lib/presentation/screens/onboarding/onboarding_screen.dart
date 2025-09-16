import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/color_constants.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Отдельные режимы: welcome (без PageView) и slider (PageView без первого экрана)
  bool _welcomeDone = false;

  // Слайдер — только страницы со 2-й по N
  late final List<OnboardingData> _allPages = [
    OnboardingData(
      title: "TRIPLY",
      subtitle: "AI-Powered Travel",
      useAnimation: true,
      animationPath: "assets/animations/animation.json",
      isWelcomeScreen: true,
    ),
    OnboardingData(
      title: "Plan Your Trip\nWith AI",
      subtitle:
          "Enjoy personalized destinations with our intelligent travel assistant.",
      svgPath: "assets/svg/travel_destination.svg",
    ),
    OnboardingData(
      title: "Book Your\n Perfect Stay",
      subtitle:
          "Browse, pick, and book your ideal stay with just a few clicks.",
      svgPath: "assets/svg/booking_travel.svg",
    ),
    OnboardingData(
      title: "Design Your\n Adventure",
      subtitle:
          "Plan your walk with AI-powered directions and personalized highlights.",
      svgPath: "assets/svg/community_travel.svg",
    ),
  ];
  List<OnboardingData> get _slides => _allPages.sublist(1);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final AnimationController _lottieController;
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: _welcomeDone ? _buildSlider() : _buildWelcome(),
        ),
      ),
    );
  }

 
  Widget _buildWelcome() {
    final data = _allPages.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 24), // было 40 → контент чуть выше

          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.topCenter,
              child: _buildLottieAnimation(data.animationPath!),
            ),
          ),

          const SizedBox(height: 16), // было 32 → заголовок поднимается

          // Заголовок: крупнее и немного смещён вверх без отрицательного padding
          Transform.translate(
            offset: const Offset(0, -6), // безопасный подъём вверх (6px)
            child: Text(
              data.title,
              style: TextStyle(
                fontSize: 60, // увеличение размера
                fontWeight: FontWeight.w900, // плотнее для логотипа
                color: AppColors.primary,
                letterSpacing: 2,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 18, // лучше читается
              color: Colors.grey,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _welcomeDone = true;
                  _currentPage = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fixedSize: const Size(220, 56),
              ),
              child: const Text(
                'Get started',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _goToLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  children: [
                    const TextSpan(text: "Already have an account? "),
                    TextSpan(
                      text: "Login",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }



  // ---------- Slider (страницы 2..N, с индикатором и свайпом) ----------
  Widget _buildSlider() {
    return Column(
      children: [
        // Skip сверху справа
        Padding(
          padding: const EdgeInsets.only(top: 16, right: 24),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _goToHome,
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildSlidePage(_slides[index]);
            },
          ),
        ),
        // Индикатор точек только в режиме слайдера
        SmoothPageIndicator(
          controller: _pageController,
          count: _slides.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 3,
            spacing: 8,
            activeDotColor: AppColors.primary,
            dotColor: Colors.grey!,
          ),
        ),
        const SizedBox(height: 32),
        // Кнопка Next/Start exploring по центру
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: ElevatedButton(
              onPressed:
                  _currentPage == _slides.length - 1 ? _goToHome : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fixedSize: const Size(220, 56),
              ),
              child: Text(
                _currentPage == _slides.length - 1 ? 'Start exploring' : 'Next',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _goToLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  children: [
                    const TextSpan(text: "Already have an account? "),
                    TextSpan(
                      text: "Login",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSlidePage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.topCenter,
              child: data.useAnimation
                  ? _buildLottieAnimation(data.animationPath!)
                  : _buildSvgImage(data.svgPath!),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLottieAnimation(String animationPath) {
    final screenWidth = MediaQuery.of(context).size.width;
    final animationSize = screenWidth * 0.95;
    return SizedBox(
      width: animationSize,
      height: animationSize,
      child: Lottie.asset(
        animationPath,
        controller: _lottieController,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        frameRate: FrameRate.max,
        filterQuality: FilterQuality.high,
        addRepaintBoundary: true,
        onLoaded: (composition) {
          _lottieController
            ..duration = composition.duration
            ..repeat();
        },
      ),
    );
  }

  Widget _buildSvgImage(String svgPath) {
    return SvgPicture.asset(
      svgPath,
      width: 280,
      height: 280,
      fit: BoxFit.contain,
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const LoginScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const RegisterScreen(),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

// Модель данных для экранов
class OnboardingData {
  final String title;
  final String subtitle;
  final String? svgPath;
  final String? animationPath;
  final bool useAnimation;
  final bool isWelcomeScreen;

  OnboardingData({
    required this.title,
    required this.subtitle,
    this.svgPath,
    this.animationPath,
    this.useAnimation = false,
    this.isWelcomeScreen = false,
  });
}
