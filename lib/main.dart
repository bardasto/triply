// lib/main.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/color_constants.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();
  runApp(const TravelAIApp());
}

Future<void> _initializeApp() async {
  try {
    await AppConfig.load();
    await SupabaseConfig.initialize();
    AppConfig.printConfig();
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
  }
}

class TravelAIApp extends StatefulWidget {
  const TravelAIApp({Key? key}) : super(key: key);

  @override
  State<TravelAIApp> createState() => _TravelAIAppState();
}

class _TravelAIAppState extends State<TravelAIApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSubscription;

  // ✅ Флаг для контроля password recovery
  static bool _isInPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;

        debugPrint('🔑 Auth event: $event');

        if (event == AuthChangeEvent.passwordRecovery && session != null) {
          debugPrint('🔑 PASSWORD RECOVERY DETECTED!');

          // ✅ НЕ делаем signOut - используем сессию напрямую
          _isInPasswordRecovery = true;

          // ✅ Навигация с сохранением recovery сессии
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_navigatorKey.currentState != null) {
              debugPrint('🔑 NAVIGATING TO RESET SCREEN!');

              _navigatorKey.currentState!.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) {
                    debugPrint('🔑 BUILDING RESET PASSWORD SCREEN!');
                    return ResetPasswordScreen(
                      session: session,
                      onComplete: () {
                        debugPrint('🔑 Password reset completed');
                        // ✅ Сбрасываем флаг и делаем logout ПОСЛЕ смены пароля
                        _isInPasswordRecovery = false;
                      },
                    );
                  },
                ),
                (route) => false,
              );
            }
          });
        }

        // ✅ Обычный logout
        if (event == AuthChangeEvent.signedOut && !_isInPasswordRecovery) {
          debugPrint('🔑 User signed out normally');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'TRIPLY',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: _isInPasswordRecovery
            ? const SizedBox.shrink() // Пустой экран во время recovery
            : const AuthWrapper(),
      ),
    );
  }

  ThemeData _buildTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily:
          Platform.isIOS ? '.SF UI Text' : GoogleFonts.inter().fontFamily,
      useMaterial3: true,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.state) {
          case AuthViewState.initial:
          case AuthViewState.loading:
            return const InitializationScreen();
          case AuthViewState.authenticated:
            return const HomeScreen();
          case AuthViewState.unauthenticated:
          case AuthViewState.resettingPassword:
            return const OnboardingScreen();
        }
      },
    );
  }
}

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
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
