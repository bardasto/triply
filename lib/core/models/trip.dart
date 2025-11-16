// ═══════════════════════════════════════════════════════════════════════════
// TRIP MODEL - Public Trips (AI-Generated) WITH DETAILED PLACES
// For public_trips table in Supabase
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// TRANSPORT INFO
// ═══════════════════════════════════════════════════════════════════════════

class TransportInfo {
  final String fromPrevious;
  final String method;
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
// TRIP PLACE - Individual place in detailed itinerary
// ═══════════════════════════════════════════════════════════════════════════

class TripPlace {
  final String? poiId;
  final String name;
  final String type;
  final String category;
  final String description;
  final int durationMinutes;
  final String price;
  final double? priceValue;
  final double rating;
  final String address;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final List<String>? images; // ✅ NEW: Multiple photos per place
  final String? openingHours;
  final String? bestTime;
  final String? cuisine;
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
    this.images, // ✅ NEW: Multiple photos
    this.openingHours,
    this.bestTime,
    this.cuisine,
    this.transportation,
  });

  factory TripPlace.fromJson(Map<String, dynamic> json) {
    // ✅ Parse images[] array
    List<String>? imagesList;
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .where((img) => img != null && img.toString().isNotEmpty)
          .map((img) => img.toString())
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
      images: imagesList, // ✅ NEW: Multiple photos
      openingHours: json['opening_hours'] as String?,
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
      'images': images, // ✅ NEW: Multiple photos
      'opening_hours': openingHours,
      'best_time': bestTime,
      'cuisine': cuisine,
      'transportation': transportation?.toJson(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP DAY MODEL - WITH DETAILED PLACES SUPPORT
// ═══════════════════════════════════════════════════════════════════════════

class TripDay {
  final int day;
  final String title;
  final String description;
  final List<String> poiIds; // ✅ Legacy support
  final int? estimatedDurationHours;
  final List<String>? activities;
  final List<TripPlace>? places; // ✅ NEW: Detailed places
  final List<String>? images; // ✅ Day images

  TripDay({
    required this.day,
    required this.title,
    required this.description,
    this.poiIds = const [],
    this.estimatedDurationHours,
    this.activities,
    this.places,
    this.images,
  });

  factory TripDay.fromJson(Map<String, dynamic> json) {
    // Parse legacy poi_ids
    List<String> poiIdsList = [];
    if (json['poi_ids'] != null && json['poi_ids'] is List) {
      poiIdsList = (json['poi_ids'] as List).cast<String>();
    }

    // ✅ Parse detailed places
    List<TripPlace>? placesList;
    if (json['places'] != null && json['places'] is List) {
      placesList = (json['places'] as List)
          .map((p) => TripPlace.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    // Parse images
    List<String>? imagesList;
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List).cast<String>();
    }

    return TripDay(
      day: json['day'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      poiIds: poiIdsList,
      estimatedDurationHours: json['estimated_duration_hours'] as int?,
      activities: (json['activities'] as List<dynamic>?)?.cast<String>(),
      places: placesList,
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'description': description,
      'poi_ids': poiIds,
      'estimated_duration_hours': estimatedDurationHours,
      'activities': activities,
      'places': places?.map((p) => p.toJson()).toList(),
      'images': images,
    };
  }

  // ✅ Helper: Check if has detailed places
  bool get hasDetailedPlaces => places != null && places!.isNotEmpty;

  // ✅ Helper: Get places count
  int get placesCount => places?.length ?? poiIds.length;
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN TRIP CLASS
// ═══════════════════════════════════════════════════════════════════════════

class Trip {
  final String id;
  final String title;
  final String description;
  final String duration;
  final String price;
  final double rating;
  final int reviews;

  final String? city;
  final String country;
  final String? continent;
  final double? latitude;
  final double? longitude;

  final String activityType;
  final String? difficultyLevel;
  final List<String>? bestSeasons;

  final List<String>? includes;
  final List<String>? highlights;
  final List<TripDay>? itinerary; // ✅ Now supports detailed places

  final List<TripImage>? images;
  final String? heroImageUrl;

  final List<POISnapshot>? poiData;

  final int? estimatedCostMin;
  final int? estimatedCostMax;
  final String? currency;

  final String? generationId;
  final double? relevanceScore;
  final String? status;

  final int viewCount;
  final int bookmarkCount;

  final DateTime createdAt;
  final DateTime? validUntil;

  Trip({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.price,
    this.rating = 4.5,
    this.reviews = 0,
    this.city,
    required this.country,
    this.continent,
    this.latitude,
    this.longitude,
    required this.activityType,
    this.difficultyLevel,
    this.bestSeasons,
    this.includes,
    this.highlights,
    this.itinerary,
    this.images,
    this.heroImageUrl,
    this.poiData,
    this.estimatedCostMin,
    this.estimatedCostMax,
    this.currency,
    this.generationId,
    this.relevanceScore,
    this.status,
    this.viewCount = 0,
    this.bookmarkCount = 0,
    required this.createdAt,
    this.validUntil,
  });

  factory Trip.fromPublicTrip(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String,
      price: json['price'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviews: json['reviews'] as int? ?? 0,
      city: json['city'] as String?,
      country: json['country'] as String,
      continent: json['continent'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      activityType: json['activity_type'] as String,
      difficultyLevel: json['difficulty_level'] as String?,
      bestSeasons: (json['best_season'] as List<dynamic>?)?.cast<String>(),
      includes: (json['includes'] as List<dynamic>?)?.cast<String>(),
      highlights: (json['highlights'] as List<dynamic>?)?.cast<String>(),
      itinerary: (json['itinerary'] as List<dynamic>?)
          ?.map((e) => TripDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => TripImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      heroImageUrl: json['hero_image_url'] as String?,
      poiData: (json['poi_data'] as List<dynamic>?)
          ?.map((e) => POISnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedCostMin: json['estimated_cost_min'] as int?,
      estimatedCostMax: json['estimated_cost_max'] as int?,
      currency: json['currency'] as String?,
      generationId: json['generation_id'] as String?,
      relevanceScore: (json['relevance_score'] as num?)?.toDouble(),
      status: json['status'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('generation_id') && json['generation_id'] != null) {
      return Trip.fromPublicTrip(json);
    }

    return Trip(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String,
      price: json['price'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviews: json['reviews'] as int? ?? 0,
      city: json['city'] as String?,
      country: json['country'] as String? ?? '',
      continent: json['continent'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      activityType: json['activity_type'] as String? ?? 'city',
      difficultyLevel: json['difficulty_level'] as String?,
      bestSeasons: (json['best_season'] as List<dynamic>?)?.cast<String>(),
      includes: (json['includes'] as List<dynamic>?)?.cast<String>(),
      highlights: (json['highlights'] as List<dynamic>?)?.cast<String>(),
      itinerary: null,
      images: (json['images'] as List<dynamic>?)
          ?.map((imgUrl) => TripImage(
                url: imgUrl as String,
                source: 'legacy',
                altText: null,
              ))
          .toList(),
      heroImageUrl: json['image_url'] as String?,
      poiData: null,
      estimatedCostMin: json['estimated_cost_min'] as int?,
      estimatedCostMax: json['estimated_cost_max'] as int?,
      currency: json['currency'] as String?,
      generationId: null,
      relevanceScore: null,
      status: 'active',
      viewCount: 0,
      bookmarkCount: 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      validUntil: null,
    );
  }

  String? get primaryImageUrl => heroImageUrl ?? images?.first.url;

  bool get isActive {
    if (status != 'active') return false;
    if (validUntil == null) return true;
    return validUntil!.isAfter(DateTime.now());
  }

  String get priceRange {
    if (estimatedCostMin != null && estimatedCostMax != null) {
      return '${currency ?? 'EUR'} $estimatedCostMin - $estimatedCostMax';
    }
    return price;
  }

  int? get durationDays {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  bool get hasItinerary => itinerary != null && itinerary!.isNotEmpty;

  // ✅ NEW: Check if has detailed itinerary
  bool get hasDetailedItinerary {
    if (!hasItinerary) return false;
    return itinerary!.any((day) => day.hasDetailedPlaces);
  }

  // ✅ NEW: Get total places count across all days
  int get totalPlacesCount {
    if (itinerary == null) return 0;
    return itinerary!.fold(0, (sum, day) => sum + day.placesCount);
  }

  int get totalPOIsCount => poiData?.length ?? 0;

  Trip copyWith({
    String? id,
    String? title,
    String? description,
    String? duration,
    String? price,
    double? rating,
    int? reviews,
    String? city,
    String? country,
    String? continent,
    double? latitude,
    double? longitude,
    String? activityType,
    String? difficultyLevel,
    List<String>? bestSeasons,
    List<String>? includes,
    List<String>? highlights,
    List<TripDay>? itinerary,
    List<TripImage>? images,
    String? heroImageUrl,
    List<POISnapshot>? poiData,
    int? estimatedCostMin,
    int? estimatedCostMax,
    String? currency,
    String? generationId,
    double? relevanceScore,
    String? status,
    int? viewCount,
    int? bookmarkCount,
    DateTime? createdAt,
    DateTime? validUntil,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      city: city ?? this.city,
      country: country ?? this.country,
      continent: continent ?? this.continent,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      activityType: activityType ?? this.activityType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      bestSeasons: bestSeasons ?? this.bestSeasons,
      includes: includes ?? this.includes,
      highlights: highlights ?? this.highlights,
      itinerary: itinerary ?? this.itinerary,
      images: images ?? this.images,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      poiData: poiData ?? this.poiData,
      estimatedCostMin: estimatedCostMin ?? this.estimatedCostMin,
      estimatedCostMax: estimatedCostMax ?? this.estimatedCostMax,
      currency: currency ?? this.currency,
      generationId: generationId ?? this.generationId,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      createdAt: createdAt ?? this.createdAt,
      validUntil: validUntil ?? this.validUntil,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP IMAGE MODEL
// ═══════════════════════════════════════════════════════════════════════════

class TripImage {
  final String url;
  final String source;
  final String? altText;

  TripImage({
    required this.url,
    required this.source,
    this.altText,
  });

  factory TripImage.fromJson(Map<String, dynamic> json) {
    return TripImage(
      url: json['url'] as String,
      source: json['source'] as String? ?? 'unknown',
      altText: json['alt_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'source': source,
      'alt_text': altText,
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// POI SNAPSHOT MODEL
// ═══════════════════════════════════════════════════════════════════════════

class POISnapshot {
  final String poiId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final DateTime snapshotAt;

  POISnapshot({
    required this.poiId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.snapshotAt,
  });

  factory POISnapshot.fromJson(Map<String, dynamic> json) {
    return POISnapshot(
      poiId: json['poi_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      snapshotAt: DateTime.parse(json['snapshot_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poi_id': poiId,
      'name': name,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'snapshot_at': snapshotAt.toIso8601String(),
    };
  }
}
