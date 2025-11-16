
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
// EXPORTS
// ═══════════════════════════════════════════════════════════════════════════

export // Re-export all types for convenience
 type {};

