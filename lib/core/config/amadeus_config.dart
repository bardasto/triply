import 'package:flutter_dotenv/flutter_dotenv.dart';

class AmadeusConfig {
  // 🔑 API ключи из .env файла
  static String get apiKey => dotenv.env['AMADEUS_API_KEY'] ?? '';
  static String get apiSecret => dotenv.env['AMADEUS_API_SECRET'] ?? '';
  static String get baseUrl =>
      dotenv.env['AMADEUS_BASE_URL'] ?? 'https://test.api.amadeus.com';

  // 🌐 API endpoints
  static const String tokenUrl = '/v1/security/oauth2/token';
  static const String hotelsByCity =
      '/v1/reference-data/locations/hotels/by-city';
  static const String hotelOffers = '/v3/shopping/hotel-offers';
  static const String hotelsByGeocode =
      '/v1/reference-data/locations/hotels/by-geocode';

  // 🔄 Settings from .env
  static int get tokenExpiryBuffer =>
      int.parse(dotenv.env['TOKEN_EXPIRY_BUFFER'] ?? '300');
  static String get defaultCurrency => dotenv.env['DEFAULT_CURRENCY'] ?? 'EUR';
  static int get defaultAdults =>
      int.parse(dotenv.env['DEFAULT_ADULTS'] ?? '1');

  // 📊 Default search parameters
  static Map<String, dynamic> get defaultParams => {
        'adults': defaultAdults,
        'currency': defaultCurrency,
      };

  // 🌍 Popular cities for home screen
  static const List<Map<String, String>> popularCities = [
    {'name': 'Paris', 'code': 'PAR', 'country': 'France'},
    {'name': 'London', 'code': 'LON', 'country': 'United Kingdom'},
    {'name': 'New York', 'code': 'NYC', 'country': 'United States'},
    {'name': 'Tokyo', 'code': 'TYO', 'country': 'Japan'},
    {'name': 'Barcelona', 'code': 'BCN', 'country': 'Spain'},
  ];

  // 🧪 Debug method
  static void printConfig() {
    print('🔧 Amadeus Config:');
    print('  API Key: ${apiKey.isNotEmpty ? '✅ Set' : '❌ Missing'}');
    print('  API Secret: ${apiSecret.isNotEmpty ? '✅ Set' : '❌ Missing'}');
    print('  Base URL: $baseUrl');
    print('  Currency: $defaultCurrency');
    print('  Adults: $defaultAdults');
  }
}
