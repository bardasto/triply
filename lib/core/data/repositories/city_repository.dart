import '../../models/city_model.dart';

class CityRepository {
  // Hardcoded list of popular cities for search suggestions
  static final List<CityModel> _cities = [
    CityModel(
      id: '1',
      name: 'Paris',
      country: 'France',
      imageUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34',
      tripsCount: 245,
      latitude: 48.8566,
      longitude: 2.3522,
    ),
    CityModel(
      id: '2',
      name: 'Barcelona',
      country: 'Spain',
      imageUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded',
      tripsCount: 198,
      latitude: 41.3851,
      longitude: 2.1734,
    ),
    CityModel(
      id: '3',
      name: 'Rome',
      country: 'Italy',
      imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5',
      tripsCount: 187,
      latitude: 41.9028,
      longitude: 12.4964,
    ),
    CityModel(
      id: '4',
      name: 'London',
      country: 'United Kingdom',
      imageUrl: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad',
      tripsCount: 312,
      latitude: 51.5074,
      longitude: -0.1278,
    ),
    CityModel(
      id: '5',
      name: 'Amsterdam',
      country: 'Netherlands',
      imageUrl: 'https://images.unsplash.com/photo-1534351590666-13e3e96b5017',
      tripsCount: 156,
      latitude: 52.3676,
      longitude: 4.9041,
    ),
    CityModel(
      id: '6',
      name: 'Prague',
      country: 'Czech Republic',
      imageUrl: 'https://images.unsplash.com/photo-1541849546-216549ae216d',
      tripsCount: 134,
      latitude: 50.0755,
      longitude: 14.4378,
    ),
    CityModel(
      id: '7',
      name: 'Vienna',
      country: 'Austria',
      imageUrl: 'https://images.unsplash.com/photo-1516550893923-42d28e5677af',
      tripsCount: 98,
      latitude: 48.2082,
      longitude: 16.3738,
    ),
    CityModel(
      id: '8',
      name: 'Berlin',
      country: 'Germany',
      imageUrl: 'https://images.unsplash.com/photo-1560969184-10fe8719e047',
      tripsCount: 167,
      latitude: 52.5200,
      longitude: 13.4050,
    ),
    CityModel(
      id: '9',
      name: 'Lisbon',
      country: 'Portugal',
      imageUrl: 'https://images.unsplash.com/photo-1555881400-74d7acaacd8b',
      tripsCount: 145,
      latitude: 38.7223,
      longitude: -9.1393,
    ),
    CityModel(
      id: '10',
      name: 'Budapest',
      country: 'Hungary',
      imageUrl: 'https://images.unsplash.com/photo-1541963463532-d68292c34b19',
      tripsCount: 112,
      latitude: 47.4979,
      longitude: 19.0402,
    ),
    CityModel(
      id: '11',
      name: 'Athens',
      country: 'Greece',
      imageUrl: 'https://images.unsplash.com/photo-1555993539-1732b0258235',
      tripsCount: 89,
      latitude: 37.9838,
      longitude: 23.7275,
    ),
    CityModel(
      id: '12',
      name: 'Istanbul',
      country: 'Turkey',
      imageUrl: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200',
      tripsCount: 178,
      latitude: 41.0082,
      longitude: 28.9784,
    ),
    CityModel(
      id: '13',
      name: 'Dubai',
      country: 'UAE',
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c',
      tripsCount: 234,
      latitude: 25.2048,
      longitude: 55.2708,
    ),
    CityModel(
      id: '14',
      name: 'New York',
      country: 'USA',
      imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9',
      tripsCount: 456,
      latitude: 40.7128,
      longitude: -74.0060,
    ),
    CityModel(
      id: '15',
      name: 'Tokyo',
      country: 'Japan',
      imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf',
      tripsCount: 298,
      latitude: 35.6762,
      longitude: 139.6503,
    ),
    CityModel(
      id: '16',
      name: 'Singapore',
      country: 'Singapore',
      imageUrl: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd',
      tripsCount: 267,
      latitude: 1.3521,
      longitude: 103.8198,
    ),
    CityModel(
      id: '17',
      name: 'Sydney',
      country: 'Australia',
      imageUrl: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9',
      tripsCount: 189,
      latitude: -33.8688,
      longitude: 151.2093,
    ),
    CityModel(
      id: '18',
      name: 'Bangkok',
      country: 'Thailand',
      imageUrl: 'https://images.unsplash.com/photo-1508009603885-50cf7c579365',
      tripsCount: 223,
      latitude: 13.7563,
      longitude: 100.5018,
    ),
    CityModel(
      id: '19',
      name: 'Bali',
      country: 'Indonesia',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4',
      tripsCount: 198,
      latitude: -8.3405,
      longitude: 115.0920,
    ),
    CityModel(
      id: '20',
      name: 'Mumbai',
      country: 'India',
      imageUrl: 'https://images.unsplash.com/photo-1529253355930-ddbe423a2ac7',
      tripsCount: 145,
      latitude: 19.0760,
      longitude: 72.8777,
    ),
  ];

  /// Search cities by query with optional limit
  Future<List<CityModel>> searchCities({
    required String query,
    int limit = 5,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    if (query.isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();

    // Search by city name or country
    final results = _cities.where((city) {
      final cityName = city.name.toLowerCase();
      final countryName = city.country.toLowerCase();

      return cityName.contains(normalizedQuery) ||
          countryName.contains(normalizedQuery);
    }).toList();

    // Sort by relevance (exact matches first, then starts with, then contains)
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      // Exact match
      if (aName == normalizedQuery) return -1;
      if (bName == normalizedQuery) return 1;

      // Starts with
      if (aName.startsWith(normalizedQuery) &&
          !bName.startsWith(normalizedQuery)) {
        return -1;
      }
      if (bName.startsWith(normalizedQuery) &&
          !aName.startsWith(normalizedQuery)) {
        return 1;
      }

      // Sort by trips count (popularity)
      return (b.tripsCount ?? 0).compareTo(a.tripsCount ?? 0);
    });

    // Return limited results
    return results.take(limit).toList();
  }

  /// Get all cities
  Future<List<CityModel>> getAllCities() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_cities);
  }

  /// Get city by id
  Future<CityModel?> getCityById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _cities.firstWhere((city) => city.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get cities by country
  Future<List<CityModel>> getCitiesByCountry(String country) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final normalizedCountry = country.toLowerCase().trim();

    return _cities
        .where((city) => city.country.toLowerCase() == normalizedCountry)
        .toList();
  }

  /// Get popular cities (sorted by trips count)
  Future<List<CityModel>> getPopularCities({int limit = 10}) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final sortedCities = List<CityModel>.from(_cities);
    sortedCities.sort((a, b) => (b.tripsCount ?? 0).compareTo(a.tripsCount ?? 0));

    return sortedCities.take(limit).toList();
  }
}
