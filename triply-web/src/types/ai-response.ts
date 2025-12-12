/**
 * AI Response Types
 * Types for API responses from triply-workers AI generation service
 */

// ============================================================================
// Common Types
// ============================================================================

export type AIResponseType = 'trip' | 'single_place';

// ============================================================================
// Place Types (for single_place responses)
// ============================================================================

export interface AIPlaceImage {
  url: string;
  source?: 'google_places' | 'unsplash' | 'pexels';
}

export interface AIPlace {
  id: string;
  name: string;
  placeType: string;
  category: string;
  description: string;
  address: string;
  city: string;
  country: string;
  latitude: number;
  longitude: number;
  rating: number;
  reviewCount?: number;
  priceLevel?: number;
  estimatedPrice?: string;
  currency?: string;
  openingHours?: string[];
  phoneNumber?: string;
  website?: string;
  imageUrl?: string;
  images?: AIPlaceImage[];
  cuisineTypes?: string[];
  highlights?: string[];
  bestTimeToVisit?: string;
  googlePlaceId?: string;
}

export interface AISinglePlaceResponse {
  id: string;
  type: 'single_place';
  place: AIPlace;
  alternatives: AIPlace[];
  _meta: {
    original_query: string;
    intent: {
      placeType: string;
      city: string;
      criteria: string[];
    };
    generated_at: string;
    original_location?: string | null;
    original_location_type?: string | null;
    resolved_city?: string | null;
  };
}

// ============================================================================
// Trip Types (for trip responses)
// ============================================================================

export interface AITripPlace {
  poi_id?: string;
  name: string;
  type: string;
  category: string;
  description: string;
  duration_minutes: number;
  price: string;
  price_value?: number;
  rating: number;
  address: string;
  latitude: number;
  longitude: number;
  image_url?: string;
  images?: AIPlaceImage[];
  opening_hours?: string | string[] | { open_now?: boolean; weekday_text?: string[] };
  best_time?: string;
  cuisine?: string;
  cuisine_types?: string[];
}

export interface AITripDay {
  day: number;
  title: string;
  description: string;
  places: AITripPlace[];
  restaurants?: AITripPlace[];
  images?: string[];
}

export interface AITripResponse {
  id: string;
  type: 'trip';
  title: string;
  description: string;
  city: string;
  country: string;
  duration: string;
  duration_days: number;
  price: string;
  currency: string;
  hero_image_url?: string;
  includes: string[];
  highlights: string[];
  itinerary: AITripDay[];
  images?: string[];
  rating?: number;
  reviews?: number;
  estimated_cost_min?: number;
  estimated_cost_max?: number;
  activity_type?: string;
  best_season?: string[];
  _meta: {
    original_query: string;
    extracted_intent?: {
      city: string;
      durationDays: number;
      activities: string[];
    };
    modification?: string;
  };
}

// ============================================================================
// API Response Wrapper
// ============================================================================

export interface AIGenerateResponse {
  success: boolean;
  type: AIResponseType;
  data: AITripResponse | AISinglePlaceResponse;
  error?: {
    code: string;
    message: string;
    details?: string;
  };
}

// ============================================================================
// Conversation Context (for multi-turn chat)
// ============================================================================

export interface ConversationMessage {
  role: 'user' | 'assistant';
  content: string;
  type?: 'text' | 'trip' | 'places';
  tripData?: AITripResponse;
  placeData?: AISinglePlaceResponse;
  places?: AIPlace[];
  city?: string;
  country?: string;
}

// ============================================================================
// API Request Types
// ============================================================================

export interface AIGenerateRequest {
  query: string;
  city?: string;
  activity?: string;
  durationDays?: number;
  conversationContext?: ConversationMessage[];
}

// ============================================================================
// Type Guards
// ============================================================================

export function isTripResponse(data: AITripResponse | AISinglePlaceResponse): data is AITripResponse {
  return data.type === 'trip';
}

export function isSinglePlaceResponse(data: AITripResponse | AISinglePlaceResponse): data is AISinglePlaceResponse {
  return data.type === 'single_place';
}
