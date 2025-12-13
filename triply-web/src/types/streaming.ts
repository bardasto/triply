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
  | 'restaurant'
  | 'image'
  | 'prices'
  | 'price_update'
  | 'prices_complete'
  | 'complete'
  | 'error'
  // Modification events (granular updates for animations)
  | 'modification_start'
  | 'place_remove'
  | 'place_add'
  | 'restaurant_remove'
  | 'restaurant_add'
  | 'day_remove'
  | 'day_add'
  | 'modification_complete';

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
  description?: string;
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
  restaurantsCount?: number;
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

// Restaurant event data
export interface RestaurantEventData {
  dayNumber: number;
  slotIndex: number;
  restaurant: StreamingPlace;
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

// Price update event data (streaming price for individual place)
export interface PriceUpdateEventData {
  dayNumber: number;
  slotIndex: number;
  placeId: string;
  price: string;
}

// Complete event data
export interface CompleteEventData {
  tripId: string;
  message: string;
  tripData: unknown;
}

// ─────────────────────────────────────────────────────────────────────────────
// Modification Event Data Types
// ─────────────────────────────────────────────────────────────────────────────

// Modification start event
export interface ModificationStartEventData {
  isModification: true;
  modificationType: string;
  description: string;
}

// Place removal event (for exit animation)
export interface PlaceRemoveEventData {
  dayNumber: number;
  placeId: string;
}

// Place addition event (for enter animation)
export interface PlaceAddEventData {
  dayNumber: number;
  slotIndex: number;
  place: StreamingPlace;
}

// Restaurant removal event
export interface RestaurantRemoveEventData {
  dayNumber: number;
  restaurantId: string;
}

// Restaurant addition event
export interface RestaurantAddEventData {
  dayNumber: number;
  slotIndex: number;
  restaurant: StreamingPlace;
}

// Day removal event
export interface DayRemoveEventData {
  dayNumber: number;
}

// Day addition event
export interface DayAddEventData {
  dayNumber: number;
  title: string;
  description: string;
  placesCount: number;
  restaurantsCount: number;
}

// Modification complete event
export interface ModificationCompleteEventData {
  tripId: string;
  message: string;
  isModification: true;
  modificationType: string;
  trip: unknown; // Full trip data for final state sync
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

  // Modification tracking (for granular animations)
  isModification: boolean;
  modificationType: string | null;
  modificationDescription: string | null;
  // Sets of IDs being removed (for exit animations)
  removingPlaceIds: Set<string>;
  removingRestaurantIds: Set<string>;
  removingDayNumbers: Set<number>;
  // Sets of IDs being added (for enter animations)
  addingPlaceIds: Set<string>;
  addingRestaurantIds: Set<string>;
  addingDayNumbers: Set<number>;

  // Skeleton data (arrives early)
  title: string | null;
  description: string | null;
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
    restaurantsCount?: number;
  }>;

  // Places (progressively filled) - key: "dayNumber-slotIndex"
  places: Map<string, StreamingPlace>;

  // Restaurants (progressively filled) - key: "dayNumber-slotIndex"
  restaurants: Map<string, StreamingPlace>;

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
    // Modification tracking
    isModification: false,
    modificationType: null,
    modificationDescription: null,
    removingPlaceIds: new Set(),
    removingRestaurantIds: new Set(),
    removingDayNumbers: new Set(),
    addingPlaceIds: new Set(),
    addingRestaurantIds: new Set(),
    addingDayNumbers: new Set(),
    // Trip data
    title: null,
    description: null,
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
    restaurants: new Map(),
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
 * Create streaming state from existing trip data (for modifications)
 * This preserves existing trip data so modifications can be applied incrementally
 */
export function createStreamingStateFromTrip(tripData: Record<string, unknown>): StreamingTripState {
  const state = createInitialStreamingState();

  // Set skeleton data from trip
  state.title = (tripData.title as string) || null;
  state.description = (tripData.description as string) || null;
  state.city = (tripData.city as string) || null;
  state.country = (tripData.country as string) || null;
  state.duration = (tripData.duration as string) || null;
  state.durationDays = (tripData.duration_days as number) || null;
  state.theme = (tripData.activity_type as string) || null;
  state.thematicKeywords = (tripData.highlights as string[]) || [];
  state.heroImageUrl = (tripData.hero_image_url as string) || null;
  state.tripId = (tripData.id as string) || null;

  // Set estimated budget
  if (tripData.estimated_cost_min || tripData.estimated_cost_max) {
    state.estimatedBudget = {
      min: (tripData.estimated_cost_min as number) || null,
      max: (tripData.estimated_cost_max as number) || null,
      currency: (tripData.currency as string) || 'EUR',
    };
  }

  // Parse itinerary into days, places, and restaurants
  const itinerary = tripData.itinerary as Array<{
    day: number;
    title: string;
    description: string;
    places: Array<Record<string, unknown>>;
    restaurants?: Array<Record<string, unknown>>;
  }> | undefined;

  if (itinerary && Array.isArray(itinerary)) {
    for (const dayData of itinerary) {
      const dayNum = dayData.day;

      // Add day to days map
      state.days.set(dayNum, {
        title: dayData.title || `Day ${dayNum}`,
        description: dayData.description || '',
        slotsCount: dayData.places?.length || 0,
        restaurantsCount: dayData.restaurants?.length || 0,
      });

      // Add places
      if (dayData.places && Array.isArray(dayData.places)) {
        dayData.places.forEach((place, index) => {
          const key = `${dayNum}-${index}`;
          state.places.set(key, {
            id: (place.id as string) || (place.poi_id as string),
            poi_id: (place.poi_id as string),
            placeId: (place.placeId as string) || (place.place_id as string),
            name: (place.name as string) || 'Unknown',
            type: (place.type as string),
            category: (place.category as string),
            description: (place.description as string),
            duration_minutes: (place.duration_minutes as number),
            price: (place.price as string),
            price_value: (place.price_value as number),
            rating: (place.rating as number),
            address: (place.address as string),
            latitude: (place.latitude as number),
            longitude: (place.longitude as number),
            image_url: (place.image_url as string),
            images: (place.images as Array<{ url: string; source?: string }>),
            opening_hours: place.opening_hours as StreamingPlace['opening_hours'],
            best_time: (place.best_time as string),
            cuisine: (place.cuisine as string),
            cuisine_types: (place.cuisine_types as string[]),
          });
        });
      }

      // Add restaurants
      if (dayData.restaurants && Array.isArray(dayData.restaurants)) {
        dayData.restaurants.forEach((restaurant, index) => {
          const key = `${dayNum}-${index}`;
          state.restaurants.set(key, {
            id: (restaurant.id as string) || (restaurant.poi_id as string),
            poi_id: (restaurant.poi_id as string),
            placeId: (restaurant.placeId as string) || (restaurant.place_id as string),
            name: (restaurant.name as string) || 'Unknown',
            type: (restaurant.type as string) || 'restaurant',
            category: (restaurant.category as string),
            description: (restaurant.description as string),
            duration_minutes: (restaurant.duration_minutes as number),
            price: (restaurant.price as string),
            price_value: (restaurant.price_value as number),
            rating: (restaurant.rating as number),
            address: (restaurant.address as string),
            latitude: (restaurant.latitude as number),
            longitude: (restaurant.longitude as number),
            image_url: (restaurant.image_url as string),
            images: (restaurant.images as Array<{ url: string; source?: string }>),
            opening_hours: restaurant.opening_hours as StreamingPlace['opening_hours'],
            cuisine: (restaurant.cuisine as string),
          });
        });
      }
    }
  }

  // Mark as ready for modifications
  state.isConnected = true;
  state.isModification = true;
  state.phase = 'modification_start';
  state.progress = 0.1;

  return state;
}

/**
 * Convert StreamingTripState to AITripResponse format
 * Same logic as Flutter's toTripData() method
 */
export function streamingStateToTripData(state: StreamingTripState): Record<string, unknown> {
  // Build itinerary from days, places, and restaurants
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
    restaurants: Array<{
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
      cuisine?: string;
    }>;
    images: string[];
  }> = [];

  const durationDays = state.durationDays || state.days.size || 0;

  // Debug logging
  console.log("[streamingStateToTripData] durationDays:", durationDays);
  console.log("[streamingStateToTripData] state.places.size:", state.places.size);
  console.log("[streamingStateToTripData] state.restaurants.size:", state.restaurants.size);

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

    // Collect restaurants with their slot indices for sorting
    const dayRestaurantsWithIndex: Array<{ slotIndex: number; restaurant: StreamingPlace }> = [];

    // Find restaurants for this day
    state.restaurants.forEach((restaurant, key) => {
      if (key.startsWith(`${dayNum}-`)) {
        const slotIndex = parseInt(key.split('-')[1], 10) || 0;

        // Add images from placeImages if available
        const restaurantId = restaurant.placeId || restaurant.id;
        if (restaurantId && state.placeImages.has(restaurantId)) {
          const images = state.placeImages.get(restaurantId) || [];
          if (images.length > 0 && !restaurant.image_url) {
            restaurant.image_url = images[0];
          }
          restaurant.images = images.map(url => ({ url, source: 'google_places' }));
        }
        dayRestaurantsWithIndex.push({ slotIndex, restaurant });
      }
    });

    // Sort restaurants by slot index
    dayRestaurantsWithIndex.sort((a, b) => a.slotIndex - b.slotIndex);

    // Map restaurants to the correct format
    const dayRestaurants = dayRestaurantsWithIndex.map(({ restaurant }) => ({
      poi_id: restaurant.poi_id || restaurant.placeId || restaurant.id,
      name: restaurant.name,
      type: restaurant.type || 'restaurant',
      category: restaurant.category, // breakfast, lunch, dinner
      description: restaurant.description,
      duration_minutes: restaurant.duration_minutes,
      price: restaurant.price,
      price_value: restaurant.price_value,
      rating: restaurant.rating,
      address: restaurant.address,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      image_url: restaurant.image_url,
      images: restaurant.images,
      opening_hours: restaurant.opening_hours,
      cuisine: restaurant.cuisine,
    }));

    console.log(`[streamingStateToTripData] Day ${dayNum}: ${dayPlaces.length} places, ${dayRestaurants.length} restaurants`);

    itinerary.push({
      day: dayNum,
      title: dayData.title || `Day ${dayNum}`,
      description: dayData.description || '',
      places: dayPlaces,
      restaurants: dayRestaurants,
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
    description: state.description || '',
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
