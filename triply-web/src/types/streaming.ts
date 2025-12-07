/**
 * Streaming Trip Generation Types
 * Matches the backend SSE event structure from trip-orchestrator.ts
 */

// Event types from backend
export type TripEventType =
  | 'init'
  | 'skeleton'
  | 'day'
  | 'place'
  | 'image'
  | 'prices'
  | 'complete'
  | 'error';

// SSE Event structure
export interface TripStreamEvent {
  type: TripEventType;
  phase?: string;
  progress?: number;
  data?: unknown;
  message?: string;
  error?: string;
}

// Skeleton event data
export interface SkeletonEventData {
  title?: string;
  city?: string;
  country?: string;
  duration?: string;
  durationDays?: number;
  theme?: string;
  thematicKeywords?: string[];
  vibe?: string[];
  estimatedBudget?: {
    min?: number;
    max?: number;
    currency?: string;
  };
}

// Day event data
export interface DayEventData {
  dayNumber: number;
  title?: string;
  description?: string;
  slotsCount?: number;
}

// Streaming place - matches backend StreamingPlace type
export interface StreamingPlace {
  id?: string;
  placeId?: string;
  poi_id?: string;
  name: string;
  type?: string;
  category?: string;
  description?: string;
  duration_minutes?: number;
  price?: string;
  price_value?: number;
  rating?: number;
  address?: string;
  latitude?: number;
  longitude?: number;
  best_time?: string;
  // opening_hours can come from backend in different formats
  opening_hours?: {
    open_now?: boolean;
    weekday_text?: string[];
  } | string | string[] | null;
  image_url?: string | null;
  images?: Array<{ url: string; source?: string }>;
  transportation?: {
    from_previous?: string;
    method?: string;
    duration_minutes?: number;
    cost?: string;
  };
  cuisine?: string;
  cuisine_types?: string[];
}

// Place event data
export interface PlaceEventData {
  dayNumber: number;
  slotIndex: number;
  slot?: string;
  place: StreamingPlace;
}

// Image event data
export interface ImageEventData {
  type: 'hero' | 'place';
  url: string;
  placeId?: string;
  dayNumber?: number;
}

// Prices event data
export interface PricesEventData {
  min: number;
  max: number;
  currency: string;
  breakdown?: {
    accommodation?: number;
    food?: number;
    activities?: number;
    transport?: number;
  };
}

// Complete event data
export interface CompleteEventData {
  tripId: string;
  message: string;
  tripData: unknown;
}

/**
 * Streaming state that accumulates data as events arrive
 */
export interface StreamingTripState {
  // Connection status
  isConnected: boolean;
  isComplete: boolean;
  error: string | null;

  // Progress tracking
  progress: number;
  phase: string;

  // Trip ID
  tripId: string | null;

  // Skeleton data (arrives early)
  title: string | null;
  city: string | null;
  country: string | null;
  duration: string | null;
  durationDays: number | null;
  theme: string | null;
  thematicKeywords: string[];
  vibe: string[];
  estimatedBudget: {
    min: number | null;
    max: number | null;
    currency: string;
  };

  // Days (progressively filled)
  days: Map<number, {
    title: string;
    description: string;
    slotsCount: number;
  }>;

  // Places (progressively filled) - key: "dayNumber-slotIndex"
  places: Map<string, StreamingPlace>;

  // Images
  heroImageUrl: string | null;
  placeImages: Map<string, string[]>; // placeId -> urls

  // Final prices
  prices: PricesEventData | null;

  // Final complete data
  finalTripData: unknown;
}

/**
 * Create initial streaming state
 */
export function createInitialStreamingState(): StreamingTripState {
  return {
    isConnected: false,
    isComplete: false,
    error: null,
    progress: 0,
    phase: 'init',
    tripId: null,
    title: null,
    city: null,
    country: null,
    duration: null,
    durationDays: null,
    theme: null,
    thematicKeywords: [],
    vibe: [],
    estimatedBudget: {
      min: null,
      max: null,
      currency: 'EUR',
    },
    days: new Map(),
    places: new Map(),
    heroImageUrl: null,
    placeImages: new Map(),
    prices: null,
    finalTripData: null,
  };
}

/**
 * Get progress text based on current progress
 */
export function getProgressText(progress: number): string {
  if (progress < 0.15) return 'Analyzing request...';
  if (progress < 0.30) return 'Creating structure...';
  if (progress < 0.50) return 'Planning activities...';
  if (progress < 0.75) return 'Finding places...';
  if (progress < 0.90) return 'Loading images...';
  if (progress < 1.0) return 'Finalizing...';
  return 'Complete';
}

/**
 * Convert StreamingTripState to AITripResponse format
 * Same logic as Flutter's toTripData() method
 */
export function streamingStateToTripData(state: StreamingTripState): Record<string, unknown> {
  // Build itinerary from days and places
  const itinerary: Array<{
    day: number;
    title: string;
    description: string;
    places: Array<{
      poi_id?: string;
      name: string;
      type?: string;
      category?: string;
      description?: string;
      duration_minutes?: number;
      price?: string;
      price_value?: number;
      rating?: number;
      address?: string;
      latitude?: number;
      longitude?: number;
      image_url?: string | null;
      images?: Array<{ url: string; source?: string }>;
      opening_hours?: unknown;
      best_time?: string;
      cuisine?: string;
      cuisine_types?: string[];
    }>;
    images: string[];
  }> = [];

  const durationDays = state.durationDays || state.days.size || 0;

  for (let dayNum = 1; dayNum <= durationDays; dayNum++) {
    const dayData = state.days.get(dayNum);
    if (!dayData) continue;

    // Collect places with their slot indices for sorting
    const dayPlacesWithIndex: Array<{ slotIndex: number; place: StreamingPlace }> = [];

    // Find places for this day
    state.places.forEach((place, key) => {
      if (key.startsWith(`${dayNum}-`)) {
        // Extract slot index from key (format: "dayNumber-slotIndex")
        const slotIndex = parseInt(key.split('-')[1], 10) || 0;

        // Add images from placeImages if available
        const placeId = place.placeId || place.id;
        if (placeId && state.placeImages.has(placeId)) {
          const images = state.placeImages.get(placeId) || [];
          if (images.length > 0 && !place.image_url) {
            place.image_url = images[0];
          }
          place.images = images.map(url => ({ url, source: 'google_places' }));
        }
        dayPlacesWithIndex.push({ slotIndex, place });
      }
    });

    // Sort places by slot index to maintain order
    dayPlacesWithIndex.sort((a, b) => a.slotIndex - b.slotIndex);

    // Map places to the correct format preserving all fields including opening_hours
    const dayPlaces = dayPlacesWithIndex.map(({ place }) => ({
      poi_id: place.poi_id || place.placeId || place.id,
      name: place.name,
      type: place.type || place.category || 'attraction',
      category: place.category,
      description: place.description,
      duration_minutes: place.duration_minutes,
      price: place.price,
      price_value: place.price_value,
      rating: place.rating,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      image_url: place.image_url,
      images: place.images,
      opening_hours: place.opening_hours, // Preserve opening_hours as-is
      best_time: place.best_time,
      cuisine: place.cuisine,
      cuisine_types: place.cuisine_types,
    }));

    itinerary.push({
      day: dayNum,
      title: dayData.title || `Day ${dayNum}`,
      description: dayData.description || '',
      places: dayPlaces,
      images: [],
    });
  }

  // Calculate total price from all places
  const currency = state.prices?.currency || state.estimatedBudget.currency || 'EUR';
  const currencySymbol = currency === 'EUR' ? '€' : currency === 'USD' ? '$' : currency;

  // Sum up price_value from all places in itinerary
  let totalPrice = 0;
  for (const day of itinerary) {
    for (const place of day.places) {
      if (place.price_value && typeof place.price_value === 'number') {
        totalPrice += place.price_value;
      }
    }
  }

  // Format price with currency symbol
  const formattedPrice = totalPrice > 0 ? `${currencySymbol}${totalPrice}` : '';

  return {
    id: state.tripId,
    type: 'trip',
    title: state.title || 'Trip',
    description: '', // Will be filled by backend or can be generated
    city: state.city || '',
    country: state.country || '',
    duration: state.duration || `${durationDays} days`,
    duration_days: durationDays,
    price: formattedPrice,
    currency: currency,
    hero_image_url: state.heroImageUrl,
    includes: [],
    highlights: state.thematicKeywords || [],
    itinerary,
    images: state.heroImageUrl ? [state.heroImageUrl] : [],
    rating: 4.5,
    reviews: 0,
    estimated_cost_min: totalPrice,
    estimated_cost_max: totalPrice,
    activity_type: state.theme,
    best_season: [],
    _meta: {
      original_query: '',
    },
  };
}
