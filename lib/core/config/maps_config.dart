import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapsConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  static String get androidKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? '';
  static String get iosKey => dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';
  static String get webKey => dotenv.env['GOOGLE_MAPS_API_KEY_WEB'] ?? '';
}
