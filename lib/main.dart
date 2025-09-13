import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'core/constants/color_constants.dart';

void main() {
  runApp(const TravelAIApp());
}

class TravelAIApp extends StatelessWidget {
  const TravelAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'TRIPLY',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      // Сразу на onboarding после native splash с анимацией
      home: const OnboardingScreen(),
    );
  }
}
