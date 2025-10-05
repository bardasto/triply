class Hotel {
  final String hotelId;
  final String name;
  final String? chainCode;
  final String iataCode;
  final GeoCode geoCode;
  final Address address;
  final String? dupeId;
  final DateTime? lastUpdate;
  final List<String> photos; // ✅ Добавлено для фото
  final String? mainPhoto; // ✅ Главное фото
  final double? rating; // ✅ Рейтинг отеля

  Hotel({
    required this.hotelId,
    required this.name,
    this.chainCode,
    required this.iataCode,
    required this.geoCode,
    required this.address,
    this.dupeId,
    this.lastUpdate,
    this.photos = const [],
    this.mainPhoto,
    this.rating,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      hotelId: json['hotelId'] ?? '',
      name: json['name'] ?? '',
      chainCode: json['chainCode'],
      iataCode: json['iataCode'] ?? '',
      geoCode: GeoCode.fromJson(json['geoCode'] ?? {}),
      address: Address.fromJson(json['address'] ?? {}),
      dupeId: json['dupeId']?.toString(),
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.tryParse(json['lastUpdate'])
          : null,
      photos: List<String>.from(json['photos'] ?? []),
      mainPhoto: json['mainPhoto'],
      rating: json['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotelId': hotelId,
      'name': name,
      'chainCode': chainCode,
      'iataCode': iataCode,
      'geoCode': geoCode.toJson(),
      'address': address.toJson(),
      'dupeId': dupeId,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'photos': photos,
      'mainPhoto': mainPhoto,
      'rating': rating,
    };
  }

  // ✅ Копирование с фотками
  Hotel copyWith({
    String? hotelId,
    String? name,
    String? chainCode,
    String? iataCode,
    GeoCode? geoCode,
    Address? address,
    String? dupeId,
    DateTime? lastUpdate,
    List<String>? photos,
    String? mainPhoto,
    double? rating,
  }) {
    return Hotel(
      hotelId: hotelId ?? this.hotelId,
      name: name ?? this.name,
      chainCode: chainCode ?? this.chainCode,
      iataCode: iataCode ?? this.iataCode,
      geoCode: geoCode ?? this.geoCode,
      address: address ?? this.address,
      dupeId: dupeId ?? this.dupeId,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      photos: photos ?? this.photos,
      mainPhoto: mainPhoto ?? this.mainPhoto,
      rating: rating ?? this.rating,
    );
  }
}

class GeoCode {
  final double latitude;
  final double longitude;

  GeoCode({
    required this.latitude,
    required this.longitude,
  });

  factory GeoCode.fromJson(Map<String, dynamic> json) {
    return GeoCode(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class Address {
  final String countryCode;
  final String? postalCode;
  final String cityName;
  final List<String> lines;

  Address({
    required this.countryCode,
    this.postalCode,
    required this.cityName,
    required this.lines,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      countryCode: json['countryCode'] ?? '',
      postalCode: json['postalCode'],
      cityName: json['cityName'] ?? '',
      lines: List<String>.from(json['lines'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'postalCode': postalCode,
      'cityName': cityName,
      'lines': lines,
    };
  }

  String get fullAddress {
    final addressParts = [
      ...lines,
      if (postalCode != null) postalCode!,
      cityName,
      countryCode,
    ];
    return addressParts.where((part) => part.isNotEmpty).join(', ');
  }
}
