// lib/presentation/screens/onboarding/models/onboarding_data.dart
import 'wave_position.dart';

class OnboardingData {
  final String title;
  final String subtitle;
  final String? svgPath;
  final String? animationPath;
  final bool useAnimation;
  final bool isWelcomeScreen;

  // ✅ ПОДДЕРЖКА И СТАРОЙ И НОВОЙ СИСТЕМЫ
  final WavePosition? waves; // для одной волны (твои настройки)
  final MultipleWaves? multipleWaves; // для множественных волн

  const OnboardingData({
    required this.title,
    required this.subtitle,
    this.svgPath,
    this.animationPath,
    this.useAnimation = false,
    this.isWelcomeScreen = false,
    this.waves, // одиночные волны
    this.multipleWaves, // множественные волны
  });

  /// Получить все волны (объединяет старую и новую системы)
  List<WavePosition> get allWaves {
    final result = <WavePosition>[];

    // Добавляем одиночную волну если есть
    if (waves != null) {
      result.add(waves!);
    }

    // Добавляем множественные волны если есть
    if (multipleWaves != null) {
      result.addAll(multipleWaves!.sortedWaves);
    }

    return result;
  }

  /// Есть ли вообще волны
  bool get hasWaves =>
      waves != null || (multipleWaves?.waves.isNotEmpty ?? false);

  // ✅ ТВОИ ТОЧНЫЕ КООРДИНАТЫ СОХРАНЕНЫ + новые возможности
  static final List<OnboardingData> pages = [
    // Welcome Screen - полноэкранные волны (как у тебя было)
    OnboardingData(
      title: "TRIPLY",
      subtitle: "AI-Powered Travel",
      useAnimation: true,
      animationPath: "assets/animations/animation.json",
      isWelcomeScreen: true,
      waves: WavePosition.fullscreen(
        svgPath: "assets/svg/svg_background.svg",
      ),
    ),

    // 🌊 SLIDE 1 - ТВОИ ТОЧНЫЕ КООРДИНАТЫ
    OnboardingData(
      title: "Plan Your Trip\nWith AI",
      subtitle:
          "Enjoy personalized destinations with our intelligent travel assistant.",
      svgPath: "assets/svg/travel_destination.svg",
      // waves: WavePosition(
      //   svgPath: "assets/svg/waves_slide1.svg",
      //   width: 0.40, // ✅ ТВОИ настройки
      //   height: 0.80, // ✅ ТВОИ настройки
      //   x: 1.17, // ✅ ТВОИ точные координаты
      //   y: -2.70, // ✅ ТВОИ точные координаты
      // ),
    ),

    // 🌊🌊 SLIDE 2 - ДВЕ ВОЛНЫ (но можешь вернуть одну если нужно)
    OnboardingData(
      title: "Book Your\nPerfect Stay",
      subtitle:
          "Browse, pick, and book your ideal stay with just a few clicks.",
      svgPath: "assets/svg/booking_travel.svg",
      // ✅ ВЫБЕРИ ОДИН ВАРИАНТ:

      // ВАРИАНТ A: Множественные волны (новое)
      // multipleWaves: MultipleWaves.dual(
      //   firstWave: WavePosition(
      //     svgPath: "assets/svg/waves_slide2.svg",
      //     width: 0.40,
      //     height: 1.20,
      //     x: -1.53, // твоя координата слева
      //     y: 0.43, // твоя координата по центру
      //     zIndex: 0, // задний слой
      //   ),
      //   secondWave: WavePosition(
      //     svgPath: "assets/svg/waves_slide3.2.svg", // другой файл
      //     width: 0.25,
      //     height: 0.3,
      //     x: 1.0, // справа
      //     y: -1.508, // сверху
      //     zIndex: 1, // передний слой
      //   ),
      // ),

      // ВАРИАНТ B: Одна волна (твои оригинальные настройки)
      // Раскомментируй если хочешь вернуть:
      /*
      waves: WavePosition(
        svgPath: "assets/svg/waves_slide2.svg",
        width: 0.40,
        height: 1.20,
        x: -1.25,
        y: 0.44,
      ),
      */
    ),

    // 🌊 SLIDE 3 - ТВОИ ТОЧНЫЕ КООРДИНАТЫ
    OnboardingData(
      title: "Design Your\nAdventure",
      subtitle:
          "Plan your walk with AI-powered directions and personalized highlights.",
      svgPath: "assets/svg/community_travel.svg",
      // waves: WavePosition(
      //   svgPath: "assets/svg/waves_slide3.svg",
      //   width: 0.60, // ✅ ТВОИ настройки
      //   height: 0.50, // ✅ ТВОИ настройки
      //   x: -1.18, // ✅ ТВОИ точные координаты
      //   y: -1.30, // ✅ ТВОИ точные координаты
      // ),
    ),
  ];

  static OnboardingData get welcomePage => pages.first;
  static List<OnboardingData> get slides => pages.sublist(1);
}
