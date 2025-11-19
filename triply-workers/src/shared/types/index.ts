
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * TypeScript Models
 * Типы данных соответствующие структуре Supabase/Postgres БД
 * ═══════════════════════════════════════════════════════════════════════════
 */

// ═══════════════════════════════════════════════════════════════════════════
// CITIES TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface City {
  id: string;
  name: string;
  country: string;
  country_code: string;
  continent: Continent;
  latitude: number;
  longitude: number;
  timezone?: string;
  population?: number;
  popularity_score: number;
  google_place_id?: string;
  tripadvisor_location_id?: string;
  supported_activities: ActivityType[];
  is_active: boolean;
  last_poi_fetch_at?: string;
  created_at: string;
  updated_at: string;
}

export type Continent =
  | 'Europe'
  | 'Asia'
  | 'Africa'
  | 'North America'
  | 'South America'
  | 'Oceania'
  | 'Antarctica';

export type ActivityType =
  | 'cycling'
  | 'beach'
  | 'skiing'
  | 'mountains'
  | 'hiking'
  | 'sailing'
  | 'desert'
  | 'camping'
  | 'city'
  | 'wellness'
  | 'road_trip'
  | 'cultural'
  | 'food'
  | 'nightlife'
  | 'shopping'
  | 'sightseeing';

// ═══════════════════════════════════════════════════════════════════════════
// POIS TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface POI {
  id: string;
  city_id: string;
  name: string;
  description?: string;
  category: POICategory;
  subcategory?: string;
  latitude: number;
  longitude: number;
  address?: string;
  rating?: number;
  review_count: number;
  popularity_score: number;
  source: POISource;
  external_id: string;
  metadata: POIMetadata;
  is_active: boolean;
  last_verified_at: string;
  created_at: string;
  updated_at: string;
}

export type POISource =
  | 'google_places'
  | 'tripadvisor'
  | 'opentripmap'
  | 'manual';

export type POICategory =
  | 'museum'
  | 'restaurant'
  | 'landmark'
  | 'park'
  | 'beach'
  | 'shopping'
  | 'nightlife'
  | 'cafe'
  | 'religious'
  | 'entertainment'
  | 'nature'
  | 'other';

export interface POIMetadata {
  opening_hours?: {
    weekday_text?: string[];
    open_now?: boolean;
  };
  price_level?: number;
  photos?: Array<{
    reference: string;
    url?: string;
  }>;
  website?: string;
  phone?: string;
  [key: string]: any;
}

// ═══════════════════════════════════════════════════════════════════════════
// GENERATED_TRIPS TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface GeneratedTrip {
  id: string;
  title: string;
  description: string;
  duration: string;
  price: number;
  city: string;
  country: string;
  latitude: number;
  longitude: number;
  activity_type: ActivityType;
  itinerary: TripItinerary;
  poi_data: POISnapshot[];
  images: ImageMetadata[];
  hero_image_url?: string;
  highlights?: string[];
  includes?: string[];
  recommended_budget?: Budget;
  best_seasons?: string[];
  difficulty_level?: string;
  suitable_for?: string[];
  view_count: number;
  favorite_count: number;
  relevance_score: number;
  generated_for_user_id?: string;
  generation_id?: string;
  data_sources: string[];
  generation_model: string;
  is_draft: boolean;
  is_featured: boolean;
  valid_until: string;
  created_at: string;
  updated_at: string;
}

export interface TripItinerary {
  days: TripDay[];
}

export interface TripPlace {
  poi_id?: string | null;
  name: string;
  type: string;
  category: string;
  description: string;
  duration_minutes: number;
  price: string;
  price_value?: number | null;
  rating: number;
  address: string;
  latitude: number;
  longitude: number;
  google_place_id?: string;
  image_url?: string;
  opening_hours?: string;
  best_time?: string;
  cuisine?: string;
  transportation?: {
    from_previous: string;
    method: string;
    duration_minutes: number;
    cost: string;
  };
}

export interface TripDay {
  day: number;
  title: string;
  description: string;
  poi_ids?: string[]; // Старая структура для обратной совместимости
  places?: TripPlace[]; // Новая детальная структура
  images?: string[]; // Массив URL изображений для дня
  estimated_duration_hours?: number;
  activities?: string[];
}

export interface POISnapshot {
  poi_id: string;
  name: string;
  category: string;
  latitude: number;
  longitude: number;
  description?: string;
  snapshot_at: string;
}

export interface ImageMetadata {
  url: string;
  source: string;
  photographer_name?: string;
  photographer_url?: string;
  alt_text?: string;
  width?: number;
  height?: number;
}

export interface Budget {
  min: number;
  max: number;
  currency: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// API_CACHE TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface ApiCache {
  id: string;
  cache_key: string;
  cache_type: CacheType;
  cached_data: any;
  ttl_hours: number;
  expires_at: string;
  cache_hits: number;
  last_hit_at?: string;
  created_at: string;
  updated_at: string;
}

export type CacheType =
  | 'weather'
  | 'place_status'
  | 'price'
  | 'events'
  | 'images'
  | 'other';

// ═══════════════════════════════════════════════════════════════════════════
// GENERATION_LOGS TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface GenerationLog {
  id: string;
  generation_id: string;
  status: GenerationStatus;
  total_tokens?: number;
  prompt_tokens?: number;
  completion_tokens?: number;
  model_version?: string;
  duration_ms?: number;
  trips_generated: number;
  trips_saved: number;
  error_message?: string;
  metadata?: Record<string, any>;
  created_by?: string;
  created_at: string;
}

export type GenerationStatus =
  | 'pending'
  | 'running'
  | 'completed'
  | 'failed'
  | 'partial_failed'
  | 'cancelled';

// ═══════════════════════════════════════════════════════════════════════════
// TRIP_IMAGES_METADATA TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface TripImageMetadata {
  id: string;
  trip_id: string;
  source_url: string;
  source_api: ImageSource;
  external_id?: string;
  photographer_name?: string;
  photographer_url?: string;
  license?: string;
  is_hero: boolean;
  display_order: number;
  width?: number;
  height?: number;
  aspect_ratio?: number;
  alt_text?: string;
  created_at: string;
  updated_at: string;
}

export type ImageSource = 'unsplash' | 'pexels' | 'pixabay' | 'custom';

// ═══════════════════════════════════════════════════════════════════════════
// USER_PREFERENCES TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface UserPreferences {
  id: string;
  user_id: string;
  preferred_activities?: ActivityType[];
  budget_range?: {
    min: number;
    max: number;
    currency: string;
  };
  preferred_continents?: Continent[];
  preferred_seasons?: string[];
  travel_style?: string;
  group_size?: number;
  accessibility_needs?: string[];
  dietary_restrictions?: string[];
  interests?: string[];
  languages?: string[];
  auto_generate_enabled: boolean;
  max_trips_to_generate: number;
  last_generation_at?: string;
  created_at: string;
  updated_at: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// TRIP_INTERACTIONS TABLE
// ═══════════════════════════════════════════════════════════════════════════

export interface TripInteraction {
  id: string;
  trip_id: string;
  user_id?: string;
  interaction_type: InteractionType;
  interaction_data?: Record<string, any>;
  session_id?: string;
  created_at: string;
}

export type InteractionType =
  | 'view'
  | 'favorite'
  | 'share'
  | 'book'
  | 'rate'
  | 'report';

// ═══════════════════════════════════════════════════════════════════════════
// INPUT/OUTPUT TYPES для Workers
// ═══════════════════════════════════════════════════════════════════════════

export interface CityInput {
  name: string;
  country: string;
  country_code: string;
  continent: Continent;
  latitude: number;
  longitude: number;
  timezone?: string;
  population?: number;
  popularity_score?: number;
  google_place_id?: string;
  supported_activities?: ActivityType[];
}

export interface POIInput {
  city_id: string;
  name: string;
  description?: string;
  category: POICategory;
  subcategory?: string;
  latitude: number;
  longitude: number;
  address?: string;
  rating?: number;
  review_count?: number;
  popularity_score?: number;
  source: POISource;
  external_id: string;
  metadata?: POIMetadata;
}

export interface TripGenerationParams {
  city_id: string;
  city_name: string;
  country: string;
  activity_type: ActivityType;
  duration_days: number;
  poi_count: number;
  user_id?: string;
  generation_id: string;
  usedPOIIds?: Set<string>; // ✅ Track used POIs to ensure diversity
}

export interface TripGenerationResult {
  success: boolean;
  trip_id?: string;
  error?: string;
  tokens_used?: number;
  duration_ms: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// BATCH JOB TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface BatchJobConfig {
  job_id: string;
  job_type: 'seed_cities' | 'seed_pois' | 'generate_trips' | 'refresh_cache';
  status: 'pending' | 'running' | 'completed' | 'failed';
  total_items: number;
  processed_items: number;
  failed_items: number;
  start_time: string;
  end_time?: string;
  error_log: string[];
  metadata?: Record<string, any>;
}

export interface SeedCitiesJobParams {
  countries?: string[];
  min_population?: number;
  batch_size?: number;
}

export interface SeedPOIsJobParams {
  city_ids?: string[];
  per_city_limit?: number;
  categories?: POICategory[];
  batch_size?: number;
}

export interface GenerateTripsJobParams {
  city_ids?: string[];
  activity_types?: ActivityType[];
  trips_per_city?: number;
  generation_id: string;
  batch_size?: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// UTILITY TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface GeoLocation {
  latitude: number;
  longitude: number;
}

export interface BoundingBox {
  north: number;
  south: number;
  east: number;
  west: number;
}

export interface DistanceCalculation {
  from: GeoLocation;
  to: GeoLocation;
  distance_km: number;
  duration_minutes?: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// API RESPONSE TYPES
// ═══════════════════════════════════════════════════════════════════════════

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
  metadata?: {
    timestamp: string;
    request_id?: string;
    duration_ms?: number;
  };
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  per_page: number;
  has_more: boolean;
}

// ═══════════════════════════════════════════════════════════════════════════
// PLACES CACHING SYSTEM (Google Places API Policy Compliant)
// Purpose: 30-day cache with 15-day refresh cycle
// ═══════════════════════════════════════════════════════════════════════════

export interface PlaceCatalog {
  id: string;
  google_place_id: string; // ✅ Can store indefinitely
  latitude?: number; // ✅ Can cache for 30 days
  longitude?: number; // ✅ Can cache for 30 days
  coordinates_cached_at?: string;
  city?: string;
  country_code?: string;
  place_type: PlaceType;
  category?: string;
  tags: string[];
  poi_id?: string;
  is_active: boolean;
  priority: number;
  created_at: string;
  updated_at: string;
}

export type PlaceType = 'restaurant' | 'attraction' | 'hotel' | 'cafe' | 'museum' | 'park' | 'other';

export interface PlaceCache {
  id: string;
  place_catalog_id: string;

  // ⚠️ Cached data (must refresh every 15 days, expires after 30 days)
  name: string;
  formatted_address?: string;
  international_phone_number?: string;
  website?: string;
  rating?: number;
  user_ratings_total?: number;
  price_level?: number;
  cuisine_types: string[];
  opening_hours?: OpeningHours;
  current_opening_hours?: OpeningHours;
  is_open_now?: boolean;
  photos?: PlacePhoto[];
  reviews?: PlaceReview[];
  business_status?: string;
  types: string[];
  editorial_summary?: string;

  // Cache management
  cached_at: string;
  expires_at: string;
  next_refresh_at: string;
  refresh_count: number;
  last_api_call_at?: string;
  raw_data?: any;

  // Metadata
  created_at: string;
  updated_at: string;
}

export interface PlacePhoto {
  photo_reference: string;
  width: number;
  height: number;
  attributions?: string[];
}

export interface PlaceReview {
  author_name: string;
  rating: number;
  text: string;
  time: number;
  relative_time_description?: string;
}

export interface CacheRefreshLog {
  id: string;
  place_catalog_id: string;
  refresh_type: RefreshType;
  status: RefreshStatus;
  error_message?: string;
  error_code?: string;
  api_latency_ms?: number;
  refreshed_at: string;
  triggered_by?: string;
}

export type RefreshType = 'scheduled' | 'manual' | 'on_demand';
export type RefreshStatus = 'success' | 'failed' | 'skipped';

// ═══════════════════════════════════════════════════════════════════════════
// CACHED RESTAURANT DATA (Using PlaceCache)
// ═══════════════════════════════════════════════════════════════════════════

export interface CachedRestaurant {
  // From catalog (permanent)
  catalog_id: string;
  google_place_id: string;
  latitude?: number;
  longitude?: number;
  category?: string;
  tags: string[];

  // From cache (temporary, refreshed every 15 days)
  name: string;
  formatted_address?: string;
  phone?: string;
  website?: string;
  rating?: number;
  user_ratings_total?: number;
  price_level?: number;
  cuisine_types: string[];
  opening_hours?: OpeningHours;
  is_open_now?: boolean;
  photos?: PlacePhoto[];
  reviews?: PlaceReview[];

  // Cache metadata
  cached_at: string;
  expires_at: string;
  cache_status: CacheStatus;
}

export type CacheStatus = 'fresh' | 'needs_refresh' | 'expired' | 'missing';

export interface OpeningHours {
  weekday_text?: string[];
  open_now?: boolean;
  periods?: Array<{
    open: { day: number; time: string };
    close: { day: number; time: string };
  }>;
}

// Input types for creating places
export interface PlaceCatalogInput {
  google_place_id: string;
  latitude?: number;
  longitude?: number;
  city?: string;
  country_code?: string;
  place_type: PlaceType;
  category?: string;
  tags?: string[];
  poi_id?: string;
  priority?: number;
}

export interface PlaceCacheInput {
  place_catalog_id: string;
  name: string;
  formatted_address?: string;
  international_phone_number?: string;
  website?: string;
  rating?: number;
  user_ratings_total?: number;
  price_level?: number;
  cuisine_types?: string[];
  opening_hours?: OpeningHours;
  current_opening_hours?: OpeningHours;
  is_open_now?: boolean;
  photos?: PlacePhoto[];
  reviews?: PlaceReview[];
  business_status?: string;
  types?: string[];
  editorial_summary?: string;
  raw_data?: any;
}

// ═══════════════════════════════════════════════════════════════════════════
// DEPRECATED: Old Restaurant Types (for backward compatibility)
// These are kept for reference but should not be used in new code
// ═══════════════════════════════════════════════════════════════════════════

export interface MenuItem {
  id: string;
  restaurant_id: string;

  // Item Info
  name: string;
  description?: string;
  category?: MenuCategory;

  // Pricing
  price?: number;
  currency: string;

  // Details
  ingredients?: string[];
  allergens?: string[];
  dietary_tags?: DietaryTag[];

  // Source
  source_type: MenuItemSource;
  source_image_url?: string;
  ocr_confidence?: number; // 0.00 to 1.00

  // Popularity
  popularity_score: number; // 0.00 to 1.00
  is_signature_dish: boolean;

  // Status
  is_active: boolean;
  verified_at?: string;

  // Metadata
  created_at: string;
  updated_at: string;
}

export type MenuCategory =
  | 'appetizer'
  | 'soup'
  | 'salad'
  | 'main_course'
  | 'side_dish'
  | 'dessert'
  | 'beverage'
  | 'alcohol'
  | 'other';

export type DietaryTag =
  | 'vegetarian'
  | 'vegan'
  | 'gluten_free'
  | 'dairy_free'
  | 'nut_free'
  | 'halal'
  | 'kosher'
  | 'spicy'
  | 'organic';

export type MenuItemSource = 'ml' | 'manual' | 'api';

export interface RestaurantPhoto {
  id: string;
  restaurant_id: string;
  menu_item_id?: string;

  // Photo Info
  photo_url: string;
  photo_reference?: string; // Google Places reference

  // Classification
  photo_type: PhotoType;
  confidence?: number; // ML classification confidence

  // Attribution
  source: PhotoSource;
  photographer_name?: string;

  // Dimensions
  width?: number;
  height?: number;

  // Display
  display_order: number;
  is_primary: boolean;

  // Metadata
  created_at: string;
  updated_at: string;
}

export type PhotoType = 'menu' | 'food' | 'interior' | 'exterior' | 'dish';
export type PhotoSource = 'google_places' | 'user_upload' | 'ml_generated';

export interface RestaurantReview {
  id: string;
  restaurant_id: string;

  // Review Content
  author_name?: string;
  author_profile_url?: string;
  rating: number; // 1.0 to 5.0
  comment?: string;

  // Source
  source: ReviewSource;
  external_review_id?: string;

  // Sentiment (ML-based)
  sentiment_score?: number; // -1.00 to 1.00
  sentiment_label?: SentimentLabel;

  // Helpfulness
  helpful_count: number;

  // Timing
  review_date: string;

  // Metadata
  created_at: string;
  updated_at: string;
}

export type ReviewSource = 'google' | 'tripadvisor' | 'yelp' | 'internal';
export type SentimentLabel = 'positive' | 'neutral' | 'negative';

// Input types for creating restaurants
export interface RestaurantInput {
  poi_id?: string;
  name: string;
  description?: string;
  cuisine_types?: string[];
  address?: string;
  latitude: number;
  longitude: number;
  phone?: string;
  website?: string;
  rating?: number;
  google_rating?: number;
  google_review_count?: number;
  price_level?: number;
  google_place_id?: string;
  opening_hours?: OpeningHours;
  features?: string[];
  dietary_options?: string[];
}

export interface MenuItemInput {
  restaurant_id: string;
  name: string;
  description?: string;
  category?: MenuCategory;
  price?: number;
  ingredients?: string[];
  allergens?: string[];
  dietary_tags?: DietaryTag[];
  source_type?: MenuItemSource;
  source_image_url?: string;
  ocr_confidence?: number;
}

// ═══════════════════════════════════════════════════════════════════════════
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════

export // Re-export all types for convenience
 type {};

