class CountryModel {
  final String id;
  final String name;
  final String continent;
  final String? imageUrl;
  final String? flagEmoji;
  final double rating;
  final String? description;
  final double? latitude; // ✅ Добавлено
  final double? longitude; // ✅ Добавлено

  CountryModel({
    required this.id,
    required this.name,
    required this.continent,
    this.imageUrl,
    this.flagEmoji,
    this.rating = 0.0,
    this.description,
    this.latitude, // ✅ Добавлено
    this.longitude, // ✅ Добавлено
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      continent: json['continent'] ?? '',
      imageUrl: json['image_url'],
      flagEmoji: json['flag_emoji'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      description: json['description'],
      latitude: json['latitude']?.toDouble(), // ✅ Добавлено
      longitude: json['longitude']?.toDouble(), // ✅ Добавлено
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'continent': continent,
      'image_url': imageUrl,
      'flag_emoji': flagEmoji,
      'rating': rating,
      'description': description,
      'latitude': latitude, // ✅ Добавлено
      'longitude': longitude, // ✅ Добавлено
    };
  }
}
