// ═══════════════════════════════════════════════════════════════════════════
// RESTAURANT MODEL - Database Restaurant with Photos and Reviews
// ═══════════════════════════════════════════════════════════════════════════

class Restaurant {
  final String id;
  final String name;
  final String? description;
  final List<String> cuisineTypes;
  final String? address;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? website;
  final double? rating;
  final int reviewCount;
  final double? googleRating;
  final int googleReviewCount;
  final int? priceLevel;
  final double? averagePricePerPerson;
  final String currency;
  final Map<String, dynamic>? openingHours;
  final bool? isOpenNow;
  final String? googlePlaceId;
  final List<String> features;
  final List<String> dietaryOptions;
  final bool hasMenu;
  final bool isActive;
  final DateTime? lastVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final List<RestaurantPhoto>? photos;
  final List<RestaurantReview>? reviews;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    required this.cuisineTypes,
    this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.website,
    this.rating,
    required this.reviewCount,
    this.googleRating,
    required this.googleReviewCount,
    this.priceLevel,
    this.averagePricePerPerson,
    required this.currency,
    this.openingHours,
    this.isOpenNow,
    this.googlePlaceId,
    required this.features,
    required this.dietaryOptions,
    required this.hasMenu,
    required this.isActive,
    this.lastVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.photos,
    this.reviews,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // Parse photos - Support both formats:
    // 1. Migration 004 VIEW: images (TEXT[] array of URLs)
    // 2. Old format: photos (JSONB array of objects)
    List<RestaurantPhoto>? photosList;

    // First, try Migration 004 format (images as TEXT[])
    if (json['images'] != null && json['images'] is List) {
      final imageUrls = (json['images'] as List)
          .where((url) => url != null && url.toString().isNotEmpty)
          .map((url) => url.toString())
          .toList();

      if (imageUrls.isNotEmpty) {
        photosList = imageUrls.asMap().entries.map((entry) {
          return RestaurantPhoto(
            id: '${json['id']}_${entry.key}',
            restaurantId: json['id'] as String,
            photoUrl: entry.value,
            photoType: 'food', // Default type for images from Migration 004
            source: 'google_places', // Images come from Google Places API
            isPrimary: entry.key == 0, // First image is primary
            displayOrder: entry.key,
            createdAt: DateTime.now(),
          );
        }).toList();
      }
    }
    // Fallback to old format (photos as JSONB objects)
    else if (json['photos'] != null && json['photos'] is List) {
      photosList = (json['photos'] as List)
          .map((p) => RestaurantPhoto.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    // Parse reviews
    List<RestaurantReview>? reviewsList;
    if (json['reviews'] != null && json['reviews'] is List) {
      reviewsList = (json['reviews'] as List)
          .map((r) => RestaurantReview.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    // Parse arrays
    List<String> cuisineTypesList = [];
    if (json['cuisine_types'] != null && json['cuisine_types'] is List) {
      cuisineTypesList = (json['cuisine_types'] as List)
          .map((e) => e.toString())
          .toList();
    }

    List<String> featuresList = [];
    if (json['features'] != null && json['features'] is List) {
      featuresList = (json['features'] as List).map((e) => e.toString()).toList();
    }

    List<String> dietaryOptionsList = [];
    if (json['dietary_options'] != null && json['dietary_options'] is List) {
      dietaryOptionsList =
          (json['dietary_options'] as List).map((e) => e.toString()).toList();
    }

    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      cuisineTypes: cuisineTypesList,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int? ?? 0,
      googleRating: (json['google_rating'] as num?)?.toDouble(),
      googleReviewCount: json['google_review_count'] as int? ?? 0,
      priceLevel: json['price_level'] as int?,
      averagePricePerPerson:
          (json['average_price_per_person'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      openingHours: json['opening_hours'] as Map<String, dynamic>?,
      isOpenNow: json['is_open_now'] as bool?,
      googlePlaceId: json['google_place_id'] as String?,
      features: featuresList,
      dietaryOptions: dietaryOptionsList,
      hasMenu: json['has_menu'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      lastVerifiedAt: json['last_verified_at'] != null
          ? DateTime.parse(json['last_verified_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      photos: photosList,
      reviews: reviewsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cuisine_types': cuisineTypes,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'website': website,
      'rating': rating,
      'review_count': reviewCount,
      'google_rating': googleRating,
      'google_review_count': googleReviewCount,
      'price_level': priceLevel,
      'average_price_per_person': averagePricePerPerson,
      'currency': currency,
      'opening_hours': openingHours,
      'is_open_now': isOpenNow,
      'google_place_id': googlePlaceId,
      'features': features,
      'dietary_options': dietaryOptions,
      'has_menu': hasMenu,
      'is_active': isActive,
      'last_verified_at': lastVerifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'photos': photos?.map((p) => p.toJson()).toList(),
      'reviews': reviews?.map((r) => r.toJson()).toList(),
    };
  }

  /// Convert to Map format compatible with existing TripPlace format
  Map<String, dynamic> toPlaceMap() {
    final primaryPhoto = photos?.firstWhere(
      (p) => p.isPrimary,
      orElse: () => photos!.first,
    );

    return {
      'poi_id': id,
      'name': name,
      'type': 'restaurant',
      'category': 'lunch', // Default category, can be changed
      'description': description ?? '',
      'rating': rating ?? googleRating ?? 4.0,
      'address': address ?? '',
      'latitude': latitude,
      'longitude': longitude,
      'image_url': primaryPhoto?.photoUrl,
      'images': photos?.map((p) => p.photoUrl).toList() ?? [],
      'cuisine': cuisineTypes.isNotEmpty ? cuisineTypes.join(', ') : null,
      'phone': phone,
      'website': website,
      'price': _getPriceString(),
      'price_level': priceLevel,
      'opening_hours': openingHours,
      'is_open_now': isOpenNow,
      'google_place_id': googlePlaceId,
      'review_count': reviewCount,
    };
  }

  String _getPriceString() {
    if (priceLevel != null) {
      return '€' * priceLevel!;
    }
    return '€€';
  }

  /// Get primary photo URL
  String? get primaryPhotoUrl {
    if (photos == null || photos!.isEmpty) return null;
    final primary = photos!.firstWhere(
      (p) => p.isPrimary,
      orElse: () => photos!.first,
    );
    return primary.photoUrl;
  }

  /// Get all photo URLs
  List<String> get photoUrls {
    if (photos == null) return [];
    return photos!.map((p) => p.photoUrl).toList();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESTAURANT PHOTO MODEL
// ═══════════════════════════════════════════════════════════════════════════

class RestaurantPhoto {
  final String id;
  final String restaurantId;
  final String photoUrl;
  final String? photoReference;
  final String photoType; // menu, food, interior, exterior, dish
  final String source; // google_places, user_upload, ml_generated
  final int displayOrder;
  final bool isPrimary;
  final int? width;
  final int? height;
  final DateTime createdAt;

  RestaurantPhoto({
    required this.id,
    required this.restaurantId,
    required this.photoUrl,
    this.photoReference,
    required this.photoType,
    required this.source,
    required this.displayOrder,
    required this.isPrimary,
    this.width,
    this.height,
    required this.createdAt,
  });

  factory RestaurantPhoto.fromJson(Map<String, dynamic> json) {
    return RestaurantPhoto(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      photoUrl: json['photo_url'] as String,
      photoReference: json['photo_reference'] as String?,
      photoType: json['photo_type'] as String,
      source: json['source'] as String? ?? 'google_places',
      displayOrder: json['display_order'] as int? ?? 0,
      isPrimary: json['is_primary'] as bool? ?? false,
      width: json['width'] as int?,
      height: json['height'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'photo_url': photoUrl,
      'photo_reference': photoReference,
      'photo_type': photoType,
      'source': source,
      'display_order': displayOrder,
      'is_primary': isPrimary,
      'width': width,
      'height': height,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESTAURANT REVIEW MODEL
// ═══════════════════════════════════════════════════════════════════════════

class RestaurantReview {
  final String id;
  final String restaurantId;
  final String? authorName;
  final String? authorProfileUrl;
  final double rating;
  final String? comment;
  final String source; // google, tripadvisor, yelp, internal
  final String? sentimentLabel; // positive, neutral, negative
  final double? sentimentScore;
  final DateTime reviewDate;
  final DateTime createdAt;

  RestaurantReview({
    required this.id,
    required this.restaurantId,
    this.authorName,
    this.authorProfileUrl,
    required this.rating,
    this.comment,
    required this.source,
    this.sentimentLabel,
    this.sentimentScore,
    required this.reviewDate,
    required this.createdAt,
  });

  factory RestaurantReview.fromJson(Map<String, dynamic> json) {
    return RestaurantReview(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      authorName: json['author_name'] as String?,
      authorProfileUrl: json['author_profile_url'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      source: json['source'] as String? ?? 'google',
      sentimentLabel: json['sentiment_label'] as String?,
      sentimentScore: (json['sentiment_score'] as num?)?.toDouble(),
      reviewDate: DateTime.parse(json['review_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'author_name': authorName,
      'author_profile_url': authorProfileUrl,
      'rating': rating,
      'comment': comment,
      'source': source,
      'sentiment_label': sentimentLabel,
      'sentiment_score': sentimentScore,
      'review_date': reviewDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
