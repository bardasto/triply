class TripModel {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String price;
  final double rating;
  final int reviews;
  final String? imageUrl;
  final String? countryId;
  final List<String> includes;
  final List<String> images;
  final String? category;
  final bool isFeatured;

  // ✅ ГЕОЛОКАЦИЯ
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;

  // ✅ НОВЫЕ ПОЛЯ ДЛЯ ФИЛЬТРАЦИИ
  final String? activityType;
  final String? continent;

  TripModel({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.price,
    required this.rating,
    required this.reviews,
    this.imageUrl,
    this.countryId,
    this.includes = const [],
    this.images = const [],
    this.category,
    this.isFeatured = false,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.activityType,
    this.continent,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    List<String> includesList = [];
    if (json['includes'] != null) {
      if (json['includes'] is List) {
        includesList = List<String>.from(json['includes']);
      }
    }

    List<String> imagesList = [];
    if (json['images'] != null) {
      imagesList = List<String>.from(json['images']);
    }

    return TripModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      duration: json['duration'] ?? '',
      price: json['price'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      imageUrl: json['image_url'],
      countryId: json['country_id'],
      includes: includesList,
      images: imagesList,
      category: json['category'],
      isFeatured: json['is_featured'] ?? false,
      city: json['city'],
      country: json['country'],
      latitude: json['latitude'] != null
          ? (json['latitude'] is num
              ? json['latitude'].toDouble()
              : double.tryParse(json['latitude'].toString()))
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is num
              ? json['longitude'].toDouble()
              : double.tryParse(json['longitude'].toString()))
          : null,
      activityType: json['activity_type'],
      continent: json['continent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration': duration,
      'price': price,
      'rating': rating,
      'reviews': reviews,
      'image_url': imageUrl,
      'country_id': countryId,
      'includes': includes,
      'images': images,
      'category': category,
      'is_featured': isFeatured,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'activity_type': activityType,
      'continent': continent,
    };
  }
}
