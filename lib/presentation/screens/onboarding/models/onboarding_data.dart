// lib/presentation/screens/onboarding/models/onboarding_data.dart
class OnboardingData {
  final String title;
  final String subtitle;
  final String? svgPath;
  final String? animationPath;
  final bool useAnimation;
  final bool isWelcomeScreen;

  const OnboardingData({
    required this.title,
    required this.subtitle,
    this.svgPath,
    this.animationPath,
    this.useAnimation = false,
    this.isWelcomeScreen = false,
  });

  // Predefined onboarding pages
  static const List<OnboardingData> pages = [
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
      title: "Book Your\nPerfect Stay",
      subtitle:
          "Browse, pick, and book your ideal stay with just a few clicks.",
      svgPath: "assets/svg/booking_travel.svg",
    ),
    OnboardingData(
      title: "Design Your\nAdventure",
      subtitle:
          "Plan your walk with AI-powered directions and personalized highlights.",
      svgPath: "assets/svg/community_travel.svg",
    ),
  ];

  static OnboardingData get welcomePage => pages.first;
  static List<OnboardingData> get slides => pages.sublist(1);
}
