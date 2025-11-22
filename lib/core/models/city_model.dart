class CityModel {
  final String id;
  final String name;
  final String country;
  final String? imageUrl;
  final int? tripsCount;
  final double? latitude;
  final double? longitude;

  CityModel({
    required this.id,
    required this.name,
    required this.country,
    this.imageUrl,
    this.tripsCount,
    this.latitude,
    this.longitude,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      tripsCount: json['trips_count'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      if (imageUrl != null) 'image_url': imageUrl,
      if (tripsCount != null) 'trips_count': tripsCount,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'CityModel(id: $id, name: $name, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CityModel &&
        other.id == id &&
        other.name == name &&
        other.country == country;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ country.hashCode;
}
