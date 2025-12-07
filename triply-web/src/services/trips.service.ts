/**
 * Trips Service
 * Handles all trip-related API calls to Supabase
 * Uses public_trips table for home page display
 */

import { getSupabaseBrowserClient } from '@/lib/supabase/client';
import type { Tables } from '@/types/database';
import type {
  Trip,
  City,
  TripsByCity,
  TripFilters,
  TripSortOptions,
  TripDay,
  TripImage,
} from '@/types/trip';

type DBPublicTrip = Tables<'public_trips'>;

/**
 * Extract images from itinerary places
 * Note: DB stores fields in snake_case (image_url, not imageUrl)
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
function extractImagesFromItinerary(itinerary: any[]): string[] {
  const images: string[] = [];

  for (const day of itinerary) {
    // Extract from places (attractions, museums, etc.)
    if (day.places && Array.isArray(day.places)) {
      for (const place of day.places) {
        // Check snake_case first (raw DB format), then camelCase
        const imageUrl = place.image_url || place.imageUrl;
        if (imageUrl) {
          images.push(imageUrl);
        }
        // Also check images array
        if (place.images && Array.isArray(place.images)) {
          for (const img of place.images) {
            const url = typeof img === 'string' ? img : (img.url || img.image_url);
            if (url) images.push(url);
          }
        }
      }
    }
    // Extract from restaurants
    if (day.restaurants && Array.isArray(day.restaurants)) {
      for (const restaurant of day.restaurants) {
        const imageUrl = restaurant.image_url || restaurant.imageUrl;
        if (imageUrl) {
          images.push(imageUrl);
        }
      }
    }
  }

  // Remove duplicates and limit
  return [...new Set(images)];
}

/**
 * Transform database public_trips row to application Trip type
 */
function transformPublicTrip(dbTrip: DBPublicTrip): Trip {
  // Parse itinerary as raw JSON first for image extraction (keeps snake_case)
  const rawItinerary = parseJsonArray<Record<string, unknown>>(dbTrip.itinerary);
  const itinerary = parseJsonArray<TripDay>(dbTrip.itinerary);
  let images = parseJsonArray<TripImage>(dbTrip.images) as TripImage[] | string[];

  // If no images in main array, extract from itinerary places
  if (images.length === 0) {
    const extractedImages = extractImagesFromItinerary(rawItinerary);
    images = extractedImages;
  }

  // If still no images but we have hero image, use it
  if (images.length === 0 && dbTrip.hero_image_url) {
    images = [dbTrip.hero_image_url];
  }

  return {
    id: dbTrip.id,
    userId: null,
    title: dbTrip.title,
    description: dbTrip.description,
    city: dbTrip.city,
    country: dbTrip.country,
    latitude: null,
    longitude: null,
    // duration is already a string like "5 days" in public_trips
    durationDays: dbTrip.duration,
    // price is already a string like "€1500" in public_trips
    price: dbTrip.price,
    currency: dbTrip.currency || 'EUR',
    estimatedCostMin: dbTrip.estimated_cost_min,
    estimatedCostMax: dbTrip.estimated_cost_max,
    heroImageUrl: dbTrip.hero_image_url,
    images,
    includes: parseJsonArray<string>(dbTrip.includes),
    highlights: parseJsonArray<string>(dbTrip.highlights),
    itinerary,
    activityType: dbTrip.activity_type,
    difficultyLevel: dbTrip.difficulty_level as Trip['difficultyLevel'],
    bestSeason: parseJsonArray<string>(dbTrip.best_season),
    rating: null,
    reviews: null,
    viewCount: dbTrip.view_count || 0,
    bookmarkCount: dbTrip.bookmark_count || 0,
    isFavorite: false,
    isPublic: dbTrip.status === 'active',
    createdAt: dbTrip.created_at,
    updatedAt: dbTrip.created_at,
  };
}

/**
 * Safely parse JSON arrays from database
 */
function parseJsonArray<T>(value: unknown): T[] {
  if (!value) return [];
  if (Array.isArray(value)) return value as T[];
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

/**
 * Get public trips with optional filtering and sorting
 */
export async function getPublicTrips(options?: {
  filters?: TripFilters;
  sort?: TripSortOptions;
  limit?: number;
  offset?: number;
}): Promise<{ data: Trip[]; count: number; error?: string }> {
  const supabase = getSupabaseBrowserClient();
  const { filters, sort, limit = 20, offset = 0 } = options || {};

  let query = supabase
    .from('public_trips')
    .select('*', { count: 'exact' })
    .eq('status', 'active');

  // Apply filters
  if (filters?.city) {
    query = query.ilike('city', `%${filters.city}%`);
  }
  if (filters?.country) {
    query = query.ilike('country', `%${filters.country}%`);
  }
  if (filters?.activityType) {
    query = query.eq('activity_type', filters.activityType);
  }
  if (filters?.minPrice !== undefined) {
    query = query.gte('price', filters.minPrice);
  }
  if (filters?.maxPrice !== undefined) {
    query = query.lte('price', filters.maxPrice);
  }
  if (filters?.minDuration !== undefined) {
    query = query.gte('duration', filters.minDuration);
  }
  if (filters?.maxDuration !== undefined) {
    query = query.lte('duration', filters.maxDuration);
  }

  // Apply sorting
  const sortField = sort?.field === 'duration_days' ? 'duration' : (sort?.field || 'created_at');
  const sortDirection = sort?.direction || 'desc';
  query = query.order(sortField, { ascending: sortDirection === 'asc' });

  // Apply pagination
  query = query.range(offset, offset + limit - 1);

  const { data, error, count } = await query;

  if (error) {
    console.error('Error fetching public trips:', error);
    return { data: [], count: 0, error: error.message };
  }

  return {
    data: ((data || []) as DBPublicTrip[]).map(transformPublicTrip),
    count: count || 0,
  };
}

/**
 * Get trips grouped by city
 */
export async function getTripsByCity(options?: {
  limit?: number;
  citiesLimit?: number;
}): Promise<{ data: TripsByCity[]; error?: string }> {
  const supabase = getSupabaseBrowserClient();
  const { limit = 6, citiesLimit = 10 } = options || {};

  // Get all active public trips
  const { data: tripsData, error } = await supabase
    .from('public_trips')
    .select('*')
    .eq('status', 'active')
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching trips by city:', error);
    return { data: [], error: error.message };
  }

  // Group trips by city
  const tripsByCity = new Map<string, { city: City; trips: Trip[] }>();

  ((tripsData || []) as DBPublicTrip[]).forEach((dbTrip) => {
    const trip = transformPublicTrip(dbTrip);
    const cityKey = trip.city?.toLowerCase() || 'unknown';

    if (!tripsByCity.has(cityKey)) {
      tripsByCity.set(cityKey, {
        city: {
          id: cityKey,
          name: trip.city || 'Unknown',
          country: trip.country || '',
          imageUrl: trip.heroImageUrl,
          tripsCount: 0,
          latitude: null,
          longitude: null,
        },
        trips: [],
      });
    }

    const cityData = tripsByCity.get(cityKey)!;
    if (cityData.trips.length < limit) {
      cityData.trips.push(trip);
    }
    cityData.city.tripsCount++;

    // Update city image if not set
    if (!cityData.city.imageUrl && trip.heroImageUrl) {
      cityData.city.imageUrl = trip.heroImageUrl;
    }
  });

  // Sort cities by trip count and limit
  const sortedCities = Array.from(tripsByCity.values())
    .sort((a, b) => b.city.tripsCount - a.city.tripsCount)
    .slice(0, citiesLimit);

  return { data: sortedCities };
}

/**
 * Get a single trip by ID
 */
export async function getTripById(id: string): Promise<{ data: Trip | null; error?: string }> {
  const supabase = getSupabaseBrowserClient();

  const { data, error } = await supabase
    .from('public_trips')
    .select('*')
    .eq('id', id)
    .single();

  if (error) {
    // Don't log "not found" errors - this is expected when trip is in user_trips but not public_trips
    if (error.code !== 'PGRST116') {
      console.error('Error fetching trip:', error);
    }
    return { data: null, error: error.message };
  }

  return { data: data ? transformPublicTrip(data as DBPublicTrip) : null };
}

/**
 * Get trips by activity type
 */
export async function getTripsByActivityType(
  activityType: string,
  limit = 10
): Promise<{ data: Trip[]; error?: string }> {
  const supabase = getSupabaseBrowserClient();

  const { data, error } = await supabase
    .from('public_trips')
    .select('*')
    .eq('status', 'active')
    .eq('activity_type', activityType)
    .order('view_count', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error fetching trips by activity:', error);
    return { data: [], error: error.message };
  }

  return { data: ((data || []) as DBPublicTrip[]).map(transformPublicTrip) };
}

/**
 * Get featured/popular trips
 */
export async function getFeaturedTrips(limit = 8): Promise<{ data: Trip[]; error?: string }> {
  const supabase = getSupabaseBrowserClient();

  const { data, error } = await supabase
    .from('public_trips')
    .select('*')
    .eq('status', 'active')
    .order('view_count', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error fetching featured trips:', error);
    return { data: [], error: error.message };
  }

  return { data: ((data || []) as DBPublicTrip[]).map(transformPublicTrip) };
}

/**
 * Search trips by query
 */
export async function searchTrips(
  query: string,
  limit = 20
): Promise<{ data: Trip[]; error?: string }> {
  const supabase = getSupabaseBrowserClient();

  const { data, error } = await supabase
    .from('public_trips')
    .select('*')
    .eq('status', 'active')
    .or(`title.ilike.%${query}%,city.ilike.%${query}%,country.ilike.%${query}%,description.ilike.%${query}%`)
    .order('view_count', { ascending: false })
    .limit(limit);

  if (error) {
    console.error('Error searching trips:', error);
    return { data: [], error: error.message };
  }

  return { data: ((data || []) as DBPublicTrip[]).map(transformPublicTrip) };
}

/**
 * Increment view count for a trip
 * Note: This requires a database function or manual increment
 */
export async function incrementTripViews(tripId: string): Promise<void> {
  // Skip view counting for now - would need a server-side RPC function
  // to safely increment without race conditions
  console.log('View tracking for trip:', tripId);
}

/**
 * Get unique cities with trip counts
 */
export async function getCitiesWithTrips(): Promise<{ data: City[]; error?: string }> {
  const supabase = getSupabaseBrowserClient();

  const { data, error } = await supabase
    .from('public_trips')
    .select('*')
    .eq('status', 'active');

  if (error) {
    console.error('Error fetching cities:', error);
    return { data: [], error: error.message };
  }

  // Aggregate cities
  const citiesMap = new Map<string, City>();

  const trips = (data || []) as DBPublicTrip[];
  trips.forEach((trip) => {
    const cityKey = trip.city?.toLowerCase() || '';
    if (!cityKey) return;

    if (!citiesMap.has(cityKey)) {
      citiesMap.set(cityKey, {
        id: cityKey,
        name: trip.city || '',
        country: trip.country || '',
        imageUrl: trip.hero_image_url,
        tripsCount: 1,
        latitude: null,
        longitude: null,
      });
    } else {
      const city = citiesMap.get(cityKey)!;
      city.tripsCount++;
      if (!city.imageUrl && trip.hero_image_url) {
        city.imageUrl = trip.hero_image_url;
      }
    }
  });

  const cities = Array.from(citiesMap.values()).sort((a, b) => b.tripsCount - a.tripsCount);

  return { data: cities };
}
