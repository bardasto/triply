import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Инициализация .env файла
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // OAuth Configuration
  static String get oauthRedirectScheme =>
      dotenv.env['OAUTH_REDIRECT_SCHEME'] ?? 'triply://login-callback/';

  static String get googleClientIdWeb =>
      dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';

  static String get googleClientIdIos =>
      dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? '';

  static String get googleClientIdAndroid =>
      dotenv.env['GOOGLE_CLIENT_ID_ANDROID'] ?? '';

  static String get facebookAppId => dotenv.env['FACEBOOK_APP_ID'] ?? '';

  // Валидация конфигурации
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  // Debug информация
  static void printConfig() {
    print('🔧 App Configuration:');
    print(
        'Supabase URL: ${supabaseUrl.isNotEmpty ? '✅ Configured' : '❌ Missing'}');
    print(
        'Supabase Key: ${supabaseAnonKey.isNotEmpty ? '✅ Configured' : '❌ Missing'}');
    print(
        'Google Client ID: ${googleClientIdIos.isNotEmpty ? '✅ Configured' : '❌ Missing'}');
    print(
        'Facebook App ID: ${facebookAppId.isNotEmpty ? '✅ Configured' : '❌ Missing'}');
  }
}
