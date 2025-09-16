import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'app_config.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 10,
        ),
        debug: kDebugMode,
      );

      if (kDebugMode) {
        print('🚀 Supabase initialized successfully!');
        print('📡 URL: ${AppConfig.supabaseUrl}');
        print('🔑 Key configured: ${AppConfig.supabaseAnonKey.isNotEmpty}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Supabase initialization failed: $e');
      }
      rethrow;
    }
  }

  // Получение клиента Supabase
  static SupabaseClient get client => Supabase.instance.client;

  // Получение клиента аутентификации
  static GoTrueClient get auth => client.auth;

  // Получение клиента реального времени
  static RealtimeClient get realtime => client.realtime;

  // Получение клиента хранилища
  static SupabaseStorageClient get storage => client.storage;

  // ✅ ИСПРАВЛЕНО: Проверка инициализации без обращения к несуществующим свойствам
  static bool get isInitialized {
    try {
      // Проверяем что клиент существует и доступен
      final client = Supabase.instance.client;
      return client.auth != null;
    } catch (e) {
      return false;
    }
  }

  // Получение информации о текущем пользователе
  static User? get currentUser => auth.currentUser;

  // Проверка авторизации
  static bool get isAuthenticated => currentUser != null;

  // ✅ ДОБАВЛЕНО: Проверка готовности к работе
  static bool get isReady {
    return AppConfig.isConfigured && isInitialized;
  }
}
