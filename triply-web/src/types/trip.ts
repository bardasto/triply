/**
 * Application-level Trip Types
 * Used throughout the application for type-safe trip data handling
 */

// Activity types enum
export type ActivityType =
  | 'city'
  | 'beach'
  | 'adventure'
  | 'cultural'
  | 'food'
  | 'wellness'
  | 'nightlife'
  | 'shopping'
  | 'hiking'
  | 'skiing'
  | 'cycling'
  | 'sailing'
  | 'camping'
  | 'road_trip'
  | 'mountains'
  | 'desert';

export type DifficultyLevel = 'easy' | 'moderate' | 'hard' | 'extreme';

export type PlaceType =
  | 'museum'
  | 'restaurant'
  | 'cafe'
  | 'landmark'
  | 'park'
  | 'beach'
  | 'shopping'
  | 'nightlife'
  | 'attraction'
  | 'religious'
  | 'entertainment'
  | 'nature'
  | 'hotel'
  | 'other';

export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';

// Transportation info between places
export interface TransportInfo {
  fromPrevious: string;
  method: 'walk' | 'metro' | 'bus' | 'taxi' | 'uber' | 'train' | 'car';
  durationMinutes: number;
  cost: string;
}

// Image with metadata
export interface TripImage {
  url: string;
  source: 'google_places' | 'unsplash' | 'pexels' | 'user_upload';
  altText?: string;
  width?: number;
  height?: number;
}

// Opening hours format (Google Places API format)
export interface OpeningHoursData {
  open_now?: boolean;
  weekday_text?: string[];
}

// Place within itinerary
export interface TripPlace {
  poiId?: string;
  name: string;
  type: PlaceType;
  category: string;
  description: string;
  durationMinutes: number;
  price: string;
  priceValue?: number;
  rating: number;
  address: string;
  latitude: number;
  longitude: number;
  imageUrl?: string;
  images?: TripImage[];
  openingHours?: string | OpeningHoursData;
  bestTime?: string;
  cuisine?: string; // For restaurants
  transportation?: TransportInfo;
}

// Single day in itinerary
export interface TripDay {
  day: number;
  title: string;
  description: string;
  places: TripPlace[];
  restaurants: TripPlace[];
  activities?: string[];
  estimatedDurationHours?: number;
  images?: string[];
}

// POI Snapshot for quick reference
export interface POISnapshot {
  poiId: string;
  name: string;
  category: string;
  latitude: number;
  longitude: number;
  snapshotAt: string;
}

// Main Trip interface
export interface Trip {
  id: string;
  userId?: string | null;
  title: string;
  description: string | null;

  // Location
  city: string | null;
  country: string | null;
  latitude?: number | null;
  longitude?: number | null;

  // Duration & Pricing
  durationDays: string | number | null; // Can be string "5 days" from public_trips or number from ai_generated_trips
  price: string | number | null; // Can be string "€1500" from public_trips or number from ai_generated_trips
  currency: string;
  estimatedCostMin?: number | null;
  estimatedCostMax?: number | null;

  // Media
  heroImageUrl: string | null;
  images: TripImage[] | string[];

  // Content
  includes: string[];
  highlights: string[];
  itinerary: TripDay[];

  // Classification
  activityType: ActivityType | string | null;
  difficultyLevel?: DifficultyLevel | null;
  bestSeason?: string[];

  // Metrics
  rating: number | null;
  reviews: number | null;
  viewCount: number;
  bookmarkCount: number;

  // Status
  isFavorite: boolean;
  isPublic: boolean;

  // Timestamps
  createdAt: string;
  updatedAt: string;
}

// City with trip count
export interface City {
  id: string;
  name: string;
  country: string;
  imageUrl?: string | null;
  tripsCount: number;
  latitude?: number | null;
  longitude?: number | null;
}

// Trips grouped by city for homepage
export interface TripsByCity {
  city: City;
  trips: Trip[];
}

// API Response types
export interface TripsResponse {
  data: Trip[];
  count: number;
  error?: string;
}

export interface TripResponse {
  data: Trip | null;
  error?: string;
}

export interface CitiesResponse {
  data: City[];
  count: number;
  error?: string;
}

// Filter options for trips
export interface TripFilters {
  city?: string;
  country?: string;
  activityType?: ActivityType;
  minPrice?: number;
  maxPrice?: number;
  minDuration?: number;
  maxDuration?: number;
  minRating?: number;
  isPublic?: boolean;
}

// Sort options
export type TripSortField = 'created_at' | 'rating' | 'price' | 'duration_days' | 'view_count';
export type SortDirection = 'asc' | 'desc';

export interface TripSortOptions {
  field: TripSortField;
  direction: SortDirection;
}
