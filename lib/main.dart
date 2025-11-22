import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/config/supabase_config.dart';
import 'core/config/amadeus_config.dart';
import 'core/constants/color_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/trip_provider.dart'; // ✅ ДОБАВЛЕНО
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/password_recovery_dialog.dart';
import 'core/config/maps_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();
  await MapsConfig.init();

  // ✅ Явно включаем status bar и navigation bar
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // ✅ Настройка ориентации
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TravelAIApp());
}

Future<void> _initializeApp() async {
  try {
    // 🔧 Загрузка .env файла
    print('🔧 Loading environment variables...');
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');

    // 🔧 Инициализация конфигураций
    await AppConfig.load();
    await SupabaseConfig.initialize();

    // 🔧 Проверка Amadeus конфигурации (опционально)
    AmadeusConfig.printConfig();
    AppConfig.printConfig();

    print('✅ App initialization completed');
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
          debugPrint('🔑 PASSWORD RECOVERY - SHOWING DIALOG!');

          // ✅ Добавляем задержку для стабильности
          await Future.delayed(const Duration(milliseconds: 100));

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = _navigatorKey.currentContext;

            if (context != null) {
              debugPrint('🔑 Showing password recovery dialog...');

              PasswordRecoveryDialog.show(context, session).then((_) {
                debugPrint('🔑 Dialog completed successfully');
              }).catchError((error) {
                debugPrint('🔑 Dialog error: $error');
              });
            } else {
              debugPrint('🔑 ❌ Context is null, cannot show dialog');
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Authentication Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ✅ Trip Provider - Управление поездками и странами
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark, // iOS: white icons
          statusBarIconBrightness: Brightness.light, // Android: white icons
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: MaterialApp(
          title: 'TRIPLY',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: const AuthWrapper(),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily:
          Platform.isIOS ? '.SF UI Text' : GoogleFonts.inter().fontFamily,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark, // iOS: white icons
          statusBarIconBrightness: Brightness.light, // Android: white icons
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }
}

// ✅ Обертка для управления состоянием аутентификации
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
            return const HomeScreen(); // ✅ Главный экран с поездками

          case AuthViewState.unauthenticated:
          case AuthViewState.resettingPassword:
            return const OnboardingScreen();
        }
      },
    );
  }
}

// ✅ Экран загрузки
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
