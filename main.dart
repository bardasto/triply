import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lib/presentation/screens/onboarding/onboarding_screen.dart'; // ← Сразу на onboarding
import 'lib/core/constants/color_constants.dart';

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
      // ← Сразу показываем OnboardingScreen после нативного splash
      home: const OnboardingScreen(), 
    );
  }
}
