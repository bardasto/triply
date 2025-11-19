// ═══════════════════════════════════════════════════════════════════════════
// TRIP MODEL - With DETAILED ITINERARY Support
// Includes TripPlace, TripDay, and TransportInfo models
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// TRANSPORT INFO - How to get between places
// ═══════════════════════════════════════════════════════════════════════════

class TransportInfo {
  final String fromPrevious;
  final String method; // walk, metro, bus, taxi
  final int durationMinutes;
  final String cost;

  TransportInfo({
    required this.fromPrevious,
    required this.method,
    required this.durationMinutes,
    required this.cost,
  });

  factory TransportInfo.fromJson(Map<String, dynamic> json) {
    return TransportInfo(
      fromPrevious: json['from_previous'] as String? ?? '',
      method: json['method'] as String? ?? 'walk',
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      cost: json['cost'] as String? ?? '€0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_previous': fromPrevious,
      'method': method,
      'duration_minutes': durationMinutes,
      'cost': cost,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP PLACE - Individual place in itinerary (POI or restaurant)
// ═══════════════════════════════════════════════════════════════════════════

class TripPlace {
  final String? poiId;
  final String name;
  final String type; // museum, restaurant, cafe, attraction
  final String category; // attraction, breakfast, lunch, dinner
  final String description;
  final int durationMinutes;
  final String price;
  final double? priceValue;
  final double rating;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final List<Map<String, dynamic>>? images; // Multiple images from Google Places
  final dynamic openingHours; // Can be String or Map<String, dynamic>
  final String? bestTime;
  final String? cuisine; // for restaurants
  final TransportInfo? transportation;

  TripPlace({
    this.poiId,
    required this.name,
    required this.type,
    required this.category,
    required this.description,
    required this.durationMinutes,
    required this.price,
    this.priceValue,
    required this.rating,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.images,
    this.openingHours,
    this.bestTime,
    this.cuisine,
    this.transportation,
  });

  factory TripPlace.fromJson(Map<String, dynamic> json) {
    // Parse images array from Google Places
    List<Map<String, dynamic>>? imagesList;
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((img) {
            if (img is Map) {
              return Map<String, dynamic>.from(img);
            }
            return null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    return TripPlace(
      poiId: json['poi_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      price: json['price'] as String? ?? '€',
      priceValue: (json['price_value'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      images: imagesList,
      openingHours: json['opening_hours'], // Keep as dynamic (String or Map)
      bestTime: json['best_time'] as String?,
      cuisine: json['cuisine'] as String?,
      transportation: json['transportation'] != null
          ? TransportInfo.fromJson(
              json['transportation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poi_id': poiId,
      'name': name,
      'type': type,
      'category': category,
      'description': description,
      'duration_minutes': durationMinutes,
      'price': price,
      'price_value': priceValue,
      'rating': rating,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'images': images,
      'opening_hours': openingHours,
      'best_time': bestTime,
      'cuisine': cuisine,
      'transportation': transportation?.toJson(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP DAY - Individual day in itinerary
// ═══════════════════════════════════════════════════════════════════════════

class TripDay {
  final int day;
  final String title;
  final String description;
  final List<TripPlace>? places; // ✅ ATTRACTIONS, MUSEUMS, etc (NOT restaurants)
  final List<TripPlace>? restaurants; // ✅ RESTAURANTS (breakfast, lunch, dinner)
  final List<String>? poiIds; // ✅ Legacy support
  final List<String>? images;

  TripDay({
    required this.day,
    required this.title,
    required this.description,
    this.places,
    this.restaurants,
    this.poiIds,
    this.images,
  });

  factory TripDay.fromJson(Map<String, dynamic> json) {
    // Parse places (attractions, museums, NOT restaurants)
    List<TripPlace>? placesList;
    if (json['places'] != null && json['places'] is List) {
      placesList = (json['places'] as List)
          .map((p) => TripPlace.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    // ✅ Parse restaurants separately
    List<TripPlace>? restaurantsList;
    if (json['restaurants'] != null && json['restaurants'] is List) {
      restaurantsList = (json['restaurants'] as List)
          .map((r) => TripPlace.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    // Parse legacy poi_ids
    List<String>? poiIdsList;
    if (json['poi_ids'] != null && json['poi_ids'] is List) {
      poiIdsList = (json['poi_ids'] as List).map((e) => e.toString()).toList();
    }

    // Parse images
    List<String>? imagesList;
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List).map((e) => e.toString()).toList();
    }

    return TripDay(
      day: json['day'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      places: placesList,
      restaurants: restaurantsList,
      poiIds: poiIdsList,
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'description': description,
      'places': places?.map((p) => p.toJson()).toList(),
      'restaurants': restaurants?.map((r) => r.toJson()).toList(), // ✅ Restaurants separately
      'poi_ids': poiIds,
      'images': images,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP MODEL - Main trip model with detailed itinerary
// ═══════════════════════════════════════════════════════════════════════════

class TripModel {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String price;
  final double rating;
  final int reviews;
  final String imageUrl;
  final String? countryId;
  final List<String> includes;
  final List<String> images;
  final String? category;
  final bool isFeatured;
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? activityType;
  final String? continent;

  // ✅ RICH CONTENT FIELDS
  final List<String>? highlights;
  final List<TripDay>? itinerary; // ✅ Now uses TripDay objects

  TripModel({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    this.countryId,
    required this.includes,
    required this.images,
    this.category,
    this.isFeatured = false,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.activityType,
    this.continent,
    this.highlights,
    this.itinerary,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    // Parse includes
    List<String> includesList = [];
    if (json['includes'] != null) {
      if (json['includes'] is List) {
        includesList =
            (json['includes'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parse images
    List<String> imagesList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imagesList = (json['images'] as List).map((e) => e.toString()).toList();
      }
    }

    // ✅ Parse highlights
    List<String>? highlightsList;
    if (json['highlights'] != null && json['highlights'] is List) {
      highlightsList =
          (json['highlights'] as List).map((e) => e.toString()).toList();
    }

    // ✅ Parse itinerary with TripDay objects
    List<TripDay>? itineraryList;
    if (json['itinerary'] != null && json['itinerary'] is List) {
      itineraryList = (json['itinerary'] as List)
          .map((item) {
            if (item is Map) {
              return TripDay.fromJson(Map<String, dynamic>.from(item));
            }
            return null;
          })
          .whereType<TripDay>()
          .toList();
    }

    return TripModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String,
      price: json['price'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviews: json['reviews'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
      countryId: json['country_id'] as String?,
      includes: includesList,
      images: imagesList,
      category: json['category'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      city: json['city'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      activityType: json['activity_type'] as String?,
      continent: json['continent'] as String?,
      highlights: highlightsList,
      itinerary: itineraryList,
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
      'highlights': highlights,
      'itinerary': itinerary?.map((d) => d.toJson()).toList(),
    };
  }

  TripModel copyWith({
    String? id,
    String? title,
    String? description,
    String? duration,
    String? price,
    double? rating,
    int? reviews,
    String? imageUrl,
    String? countryId,
    List<String>? includes,
    List<String>? images,
    String? category,
    bool? isFeatured,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    String? activityType,
    String? continent,
    List<String>? highlights,
    List<TripDay>? itinerary,
  }) {
    return TripModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      imageUrl: imageUrl ?? this.imageUrl,
      countryId: countryId ?? this.countryId,
      includes: includes ?? this.includes,
      images: images ?? this.images,
      category: category ?? this.category,
      isFeatured: isFeatured ?? this.isFeatured,
      city: city ?? this.city,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      activityType: activityType ?? this.activityType,
      continent: continent ?? this.continent,
      highlights: highlights ?? this.highlights,
      itinerary: itinerary ?? this.itinerary,
    );
  }

  // ✅ Helper: Check if has detailed places
  bool get hasDetailedItinerary {
    if (itinerary == null || itinerary!.isEmpty) return false;
    return itinerary!
        .any((day) => day.places != null && day.places!.isNotEmpty);
  }

  // ✅ Helper: Get total places count
  int get totalPlacesCount {
    if (itinerary == null) return 0;
    return itinerary!.fold(
      0,
      (sum, day) => sum + (day.places?.length ?? 0),
    );
  }
}
