import type { Json } from "./database";
import type { OpeningHoursData } from "./trip";

export interface UserTrip {
  id: string;
  user_id: string;
  title: string;
  city: string;
  country: string;
  description: string | null;
  duration_days: number;
  price: number | null;
  currency: string;
  hero_image_url: string | null;
  images: string[] | null;
  includes: string[] | null;
  highlights: string[] | null;
  itinerary: TripItinerary[] | null;
  rating: number;
  reviews: number;
  estimated_cost_min: number | null;
  estimated_cost_max: number | null;
  activity_type: string | null;
  best_season: string[] | null;
  is_favorite: boolean;
  original_query: string | null;
  created_at: string;
  updated_at: string;
}

export interface TripItinerary {
  day: number;
  title: string;
  description?: string;
  places: TripPlace[];
  restaurants: TripPlace[];
  images?: string[];
  estimated_duration_hours?: number;
}

export interface TripPlace {
  poi_id?: string;
  name: string;
  type: string;
  category: string;
  description?: string;
  image_url?: string;
  images?: Array<{ url: string; source?: string }>;
  latitude?: number;
  longitude?: number;
  rating?: number;
  address?: string;
  duration_minutes?: number;
  price?: string;
  price_value?: number;
  opening_hours?: string | OpeningHoursData;
  best_time?: string;
  cuisine?: string;
  transportation?: {
    from_previous?: string;
    method?: string;
    duration_minutes?: number;
    cost?: string;
  };
}

export interface UserTripFilters {
  city?: string;
  country?: string;
  activityType?: string;
  isFavorite?: boolean;
  search?: string;
}

// For converting to the card format
export interface UserTripCard {
  id: string;
  title: string;
  city: string;
  country: string;
  price: number;
  currency: string;
  duration_days: number;
  rating: number;
  is_favorite: boolean;
  images: string[];
  activity_type: string | null;
  description: string | null;
}

// Restaurant categories to exclude from photos (matching Flutter logic)
const RESTAURANT_CATEGORIES = ["breakfast", "lunch", "dinner"];

function isRestaurant(place: TripPlace): boolean {
  return RESTAURANT_CATEGORIES.includes(place.category?.toLowerCase() || "");
}

export function toUserTripCard(trip: UserTrip): UserTripCard {
  // Get images from various sources (matching Flutter logic)
  const images: string[] = [];
  const maxImages = 4;

  // 1. Hero image first
  if (trip.hero_image_url && trip.hero_image_url.trim()) {
    images.push(trip.hero_image_url);
  }

  // 2. Get LIMITED images from trip.images array (only 2, like Flutter)
  if (images.length < maxImages && trip.images && Array.isArray(trip.images)) {
    let count = 0;
    for (const img of trip.images) {
      if (count >= 2) break;
      if (typeof img === "string" && img.trim() && !images.includes(img)) {
        images.push(img);
        count++;
        if (images.length >= maxImages) break;
      }
    }
  }

  // 3. Extract from itinerary places (only FIRST image from each place, excluding restaurants)
  if (images.length < maxImages && trip.itinerary && Array.isArray(trip.itinerary)) {
    for (const day of trip.itinerary) {
      if (images.length >= maxImages) break;

      if (day.places && Array.isArray(day.places)) {
        for (const place of day.places) {
          if (images.length >= maxImages) break;

          // Skip restaurants - only include places
          if (isRestaurant(place)) continue;

          // Take only FIRST image from place.images array
          if (place.images && Array.isArray(place.images) && place.images.length > 0) {
            const firstImage = place.images[0];
            const imageUrl = typeof firstImage === "string" ? firstImage : firstImage?.url;
            if (imageUrl && imageUrl.trim() && !images.includes(imageUrl)) {
              images.push(imageUrl);
              continue;
            }
          }

          // Fallback to image_url
          if (place.image_url && place.image_url.trim() && !images.includes(place.image_url)) {
            images.push(place.image_url);
          }
        }
      }
    }
  }

  return {
    id: trip.id,
    title: trip.title,
    city: trip.city,
    country: trip.country,
    price: trip.price || trip.estimated_cost_min || 0,
    currency: trip.currency || "EUR",
    duration_days: trip.duration_days || 3,
    rating: trip.rating || 4.5,
    is_favorite: trip.is_favorite || false,
    images: images,
    activity_type: trip.activity_type,
    description: trip.description,
  };
}
