"use server";

import { createClient } from "@/lib/supabase/server";
import type { UserTrip, UserTripFilters } from "@/types/user-trip";
import type { AITripResponse } from "@/types/ai-response";

/**
 * Fetch all trips for the current authenticated user
 */
export async function getUserTrips(filters?: UserTripFilters): Promise<{
  trips: UserTrip[];
  error: string | null;
}> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { trips: [], error: "Not authenticated" };
  }

  let query = supabase
    .from("ai_generated_trips")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  // Apply filters
  if (filters?.city) {
    query = query.ilike("city", `%${filters.city}%`);
  }

  if (filters?.country) {
    query = query.ilike("country", `%${filters.country}%`);
  }

  if (filters?.activityType) {
    query = query.eq("activity_type", filters.activityType);
  }

  if (filters?.isFavorite !== undefined) {
    query = query.eq("is_favorite", filters.isFavorite);
  }

  if (filters?.search) {
    query = query.or(
      `title.ilike.%${filters.search}%,city.ilike.%${filters.search}%,country.ilike.%${filters.search}%`
    );
  }

  const { data, error } = await query;

  if (error) {
    console.error("Error fetching user trips:", error);
    return { trips: [], error: error.message };
  }

  return { trips: data as UserTrip[], error: null };
}

/**
 * Get a single trip by ID for the current user
 */
export async function getUserTripById(tripId: string): Promise<{
  trip: UserTrip | null;
  error: string | null;
}> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { trip: null, error: "Not authenticated" };
  }

  const { data, error } = await supabase
    .from("ai_generated_trips")
    .select("*")
    .eq("id", tripId)
    .eq("user_id", user.id)
    .single();

  if (error) {
    console.error("Error fetching trip:", error);
    return { trip: null, error: error.message };
  }

  return { trip: data as UserTrip, error: null };
}

/**
 * Toggle favorite status for a trip
 */
export async function toggleTripFavorite(
  tripId: string,
  isFavorite: boolean
): Promise<{ success: boolean; error: string | null }> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { success: false, error: "Not authenticated" };
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { error } = await (supabase as any)
    .from("ai_generated_trips")
    .update({ is_favorite: isFavorite, updated_at: new Date().toISOString() })
    .eq("id", tripId)
    .eq("user_id", user.id);

  if (error) {
    console.error("Error toggling favorite:", error);
    return { success: false, error: error.message };
  }

  return { success: true, error: null };
}

/**
 * Delete a trip
 */
export async function deleteUserTrip(
  tripId: string
): Promise<{ success: boolean; error: string | null }> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { success: false, error: "Not authenticated" };
  }

  const { error } = await supabase
    .from("ai_generated_trips")
    .delete()
    .eq("id", tripId)
    .eq("user_id", user.id);

  if (error) {
    console.error("Error deleting trip:", error);
    return { success: false, error: error.message };
  }

  return { success: true, error: null };
}

/**
 * Get favorite trips for the current user
 */
export async function getFavoriteTrips(): Promise<{
  trips: UserTrip[];
  error: string | null;
}> {
  return getUserTrips({ isFavorite: true });
}

/**
 * Get trips grouped by city for the current user
 */
export async function getUserTripsByCity(): Promise<{
  cities: Array<{ city: string; country: string; count: number; trips: UserTrip[] }>;
  error: string | null;
}> {
  const { trips, error } = await getUserTrips();

  if (error) {
    return { cities: [], error };
  }

  // Group trips by city
  const cityMap = new Map<string, { city: string; country: string; trips: UserTrip[] }>();

  trips.forEach((trip) => {
    const key = `${trip.city}-${trip.country}`;
    if (!cityMap.has(key)) {
      cityMap.set(key, { city: trip.city, country: trip.country, trips: [] });
    }
    cityMap.get(key)!.trips.push(trip);
  });

  const cities = Array.from(cityMap.values()).map((item) => ({
    ...item,
    count: item.trips.length,
  }));

  // Sort by trip count descending
  cities.sort((a, b) => b.count - a.count);

  return { cities, error: null };
}

/**
 * Save an AI-generated trip to the user's trips
 */
export async function saveUserTrip(
  tripData: AITripResponse,
  originalQuery: string
): Promise<{ tripId: string | null; error: string | null }> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return { tripId: null, error: "Not authenticated" };
  }

  // Extract hero image from itinerary if not provided
  let heroImageUrl = tripData.hero_image_url;
  if (!heroImageUrl && tripData.itinerary && tripData.itinerary.length > 0) {
    for (const day of tripData.itinerary) {
      if (day.places && day.places.length > 0) {
        for (const place of day.places) {
          if (place.image_url) {
            heroImageUrl = place.image_url;
            break;
          }
          if (place.images && place.images.length > 0) {
            heroImageUrl = place.images[0].url;
            break;
          }
        }
        if (heroImageUrl) break;
      }
    }
  }

  // Extract all images from itinerary
  const allImages: string[] = [];
  if (tripData.images) {
    allImages.push(...tripData.images);
  }
  if (tripData.itinerary) {
    for (const day of tripData.itinerary) {
      if (day.places) {
        for (const place of day.places) {
          if (place.image_url && !allImages.includes(place.image_url)) {
            allImages.push(place.image_url);
          }
          if (place.images) {
            for (const img of place.images) {
              if (img.url && !allImages.includes(img.url)) {
                allImages.push(img.url);
              }
            }
          }
        }
      }
    }
  }

  // Transform itinerary to match DB format (same as Flutter)
  // Preserve ALL place data including opening_hours, best_time, etc.
  const dbItinerary = tripData.itinerary?.map((day) => {
    const rawPlaces = day.places || [];
    const rawRestaurants = day.restaurants || [];

    // Helper to check if a place is a restaurant based on category
    const isRestaurantCategory = (category?: string) => {
      const cat = (category || '').toLowerCase();
      return cat === 'breakfast' || cat === 'lunch' || cat === 'dinner';
    };

    // If we have separate restaurants array (new multi-agent system), use it
    // Otherwise, filter restaurants from places array (fallback for old system)
    const places = (rawRestaurants.length > 0
      ? rawPlaces  // All places are actual places
      : rawPlaces.filter(p => !isRestaurantCategory(p.category))
    ).map(p => ({
      poi_id: p.poi_id,
      name: p.name,
      type: p.type,
      category: p.category,
      description: p.description,
      duration_minutes: p.duration_minutes,
      price: p.price,
      price_value: p.price_value,
      rating: p.rating,
      address: p.address,
      latitude: p.latitude,
      longitude: p.longitude,
      image_url: p.image_url,
      images: p.images,
      opening_hours: p.opening_hours,
      best_time: p.best_time,
      cuisine: p.cuisine,
      cuisine_types: p.cuisine_types,
    }));

    const restaurants = (rawRestaurants.length > 0
      ? rawRestaurants  // Use separate restaurants array
      : rawPlaces.filter(p => isRestaurantCategory(p.category))  // Filter from places
    ).map(p => ({
      poi_id: p.poi_id,
      name: p.name,
      type: p.type,
      category: p.category,
      description: p.description,
      duration_minutes: p.duration_minutes,
      price: p.price,
      price_value: p.price_value,
      rating: p.rating,
      address: p.address,
      latitude: p.latitude,
      longitude: p.longitude,
      image_url: p.image_url,
      images: p.images,
      opening_hours: p.opening_hours,
      best_time: p.best_time,
      cuisine: p.cuisine,
      cuisine_types: p.cuisine_types,
    }));

    return {
      day: day.day,
      title: day.title,
      description: day.description,
      places,
      restaurants,
      images: day.images || [],
    };
  }) || [];

  // Parse price to number
  const priceValue = tripData.estimated_cost_min ||
    (tripData.price ? parseInt(tripData.price.replace(/[^0-9]/g, ''), 10) : null);

  const tripRecord = {
    user_id: user.id,
    title: tripData.title,
    city: tripData.city,
    country: tripData.country,
    description: tripData.description,
    duration_days: tripData.duration_days,
    price: priceValue,
    currency: tripData.currency || 'EUR',
    hero_image_url: heroImageUrl,
    images: allImages.slice(0, 10), // Limit to 10 images
    includes: tripData.includes || [],
    highlights: tripData.highlights || [],
    itinerary: dbItinerary,
    rating: tripData.rating || 4.5,
    reviews: tripData.reviews || 0,
    estimated_cost_min: tripData.estimated_cost_min,
    estimated_cost_max: tripData.estimated_cost_max,
    activity_type: tripData.activity_type,
    best_season: tripData.best_season || [],
    is_favorite: false,
    original_query: originalQuery,
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const { data, error } = await (supabase as any)
    .from("ai_generated_trips")
    .insert(tripRecord)
    .select("id")
    .single();

  if (error) {
    console.error("Error saving trip:", error);
    return { tripId: null, error: error.message };
  }

  return { tripId: data?.id || null, error: null };
}
