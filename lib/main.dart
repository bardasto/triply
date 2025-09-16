import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/color_constants.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppConfig.load();
    await SupabaseConfig.initialize();
    AppConfig.printConfig();
  } catch (e) {
    print('❌ Initialization error: $e');
  }

  runApp(const TravelAIApp());
}

class TravelAIApp extends StatelessWidget {
  const TravelAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Оборачиваем всё приложение провайдером аутентификации
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'TRIPLY',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          fontFamily:
              Platform.isIOS ? '.SF UI Text' : GoogleFonts.inter().fontFamily,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// Определяем стартовый экран на основе состояния аутентификации
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.state == AuthViewState.loading ||
            auth.state == AuthViewState.initial) {
          return const InitializationScreen();
        }
        if (auth.state == AuthViewState.authenticated) {
          return const HomeScreen();
        }
        return const OnboardingScreen();
      },
    );
  }
}

// Экран инициализации на время восстановления сессии
class InitializationScreen extends StatelessWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TRIPLY',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Initializing...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
