
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Import POIs for Cities from Google Places
 * Загружает достопримечательности для каждого города
 * ═══════════════════════════════════════════════════════════════════════════
 */

import getSupabaseAdmin, { batchInsert } from '../config/supabase.js';
import googlePlacesService from '../services/google-places.service.js';
import logger from '../utils/logger.js';
import config from '../config/env.js';
import type { City, POI, POIInput, POICategory, ActivityType } from '../models/index.js';

// ═══════════════════════════════════════════════════════════════════════════
// Activity → Google Places Type Mapping
// ═══════════════════════════════════════════════════════════════════════════

const ACTIVITY_TO_PLACE_TYPES: Record<ActivityType, string[]> = {
  cycling: ['park', 'bicycle_store', 'tourist_attraction'],
  beach: ['beach', 'resort', 'water_park'],
  skiing: ['ski_resort', 'mountain', 'tourist_attraction'],
  mountains: ['mountain', 'national_park', 'hiking_area'],
  hiking: ['park', 'hiking_area', 'trail', 'nature_reserve'],
  sailing: ['marina', 'harbor', 'yacht_club', 'tourist_attraction'],
  desert: ['tourist_attraction', 'park', 'natural_feature'],
  camping: ['campground', 'rv_park', 'park'],
  city: ['tourist_attraction', 'museum', 'landmark', 'shopping_mall'],
  wellness: ['spa', 'gym', 'health', 'beauty_salon'],
  road_trip: ['gas_station', 'rest_stop', 'scenic_point', 'tourist_attraction'],
  cultural: ['museum', 'art_gallery', 'tourist_attraction', 'landmark'],
  food: ['restaurant', 'cafe', 'bar', 'food'],
  nightlife: ['bar', 'night_club', 'casino', 'entertainment'],
  shopping: ['shopping_mall', 'store', 'market', 'boutique'],
  sightseeing: ['tourist_attraction', 'landmark', 'viewpoint', 'monument'],
};

// ═══════════════════════════════════════════════════════════════════════════
// Google Places Type → POI Category
// ═══════════════════════════════════════════════════════════════════════════

const PLACE_TYPE_TO_CATEGORY: Record<string, POICategory> = {
  museum: 'museum',
  art_gallery: 'museum',
  tourist_attraction: 'landmark',
  landmark: 'landmark',
  park: 'park',
  national_park: 'park',
  beach: 'beach',
  restaurant: 'restaurant',
  cafe: 'cafe',
  bar: 'nightlife',
  night_club: 'nightlife',
  shopping_mall: 'shopping',
  store: 'shopping',
  church: 'religious',
  mosque: 'religious',
  temple: 'religious',
  amusement_park: 'entertainment',
  zoo: 'entertainment',
  aquarium: 'entertainment',
  natural_feature: 'nature',
  mountain: 'nature',
  hiking_area: 'nature',
};

// ═══════════════════════════════════════════════════════════════════════════
// Main Function
// ═══════════════════════════════════════════════════════════════════════════

export async function importPOIsForCities(options?: {
  cityIds?: string[];
  limit?: number;
  poisPerCity?: number;
  dryRun?: boolean;
}) {
  const startTime = Date.now();
  const supabase = getSupabaseAdmin();

  const poisPerCity = options?.poisPerCity || config.POIS_PER_CITY;
  const dryRun = options?.dryRun || false;

  logger.info('🗺️  Starting POI import for cities...', {
    poisPerCity,
    dryRun,
  });

  // Get cities to process
  let query = supabase
    .from('cities')
    .select('*')
    .eq('is_active', true)
    .order('popularity_score', { ascending: false });

  if (options?.cityIds) {
    query = query.in('id', options.cityIds);
  }

  if (options?.limit) {
    query = query.limit(options.limit);
  }

  const { data: cities, error } = await query;

  if (error) {
    throw new Error(`Failed to fetch cities: ${error.message}`);
  }

  if (!cities || cities.length === 0) {
    logger.warn('No cities found to process');
    return;
  }

  logger.info(`Found ${cities.length} cities to process`);

  let totalPoisInserted = 0;
  let errorCount = 0;

  // Process each city
  for (const city of cities) {
    try {
      logger.info(`Processing city: ${city.name}, ${city.country}`);

      const pois = await fetchPOIsForCity(city, poisPerCity);

      if (pois.length === 0) {
        logger.warn(`No POIs found for ${city.name}`);
        continue;
      }

      if (!dryRun) {
        const result = await batchInsert('pois', pois, {
          chunkSize: 50,
          onConflict: 'city_id,external_id',
        });

        totalPoisInserted += result.success;
        errorCount += result.failed;
      }

      logger.info(`✅ ${city.name}: ${pois.length} POIs ${dryRun ? 'found' : 'inserted'}`);

      // Rate limiting delay
      await sleep(100);

    } catch (error) {
      logger.error(`Failed to process city ${city.name}:`, error);
      errorCount++;
    }
  }

  const duration = Date.now() - startTime;

  logger.info('✅ POI import completed', {
    citiesProcessed: cities.length,
    totalPoisInserted,
    errorCount,
    durationMs: duration,
  });

  return {
    citiesProcessed: cities.length,
    totalPoisInserted,
    errorCount,
    duration,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Fetch POIs for a City
// ═══════════════════════════════════════════════════════════════════════════

async function fetchPOIsForCity(city: City, maxPois: number): Promise<POIInput[]> {
  const pois: POIInput[] = [];
  const seenPlaceIds = new Set<string>();

  // Search for different place types
  const searchTypes = [
    'tourist_attraction',
    'museum',
    'restaurant',
    'park',
    'shopping_mall',
  ];

  for (const type of searchTypes) {
    try {
      const results = await googlePlacesService.nearbySearch({
        location: {
          lat: city.latitude,
          lng: city.longitude,
        },
        radius: config.POIS_SEARCH_RADIUS_METERS,
        type,
      });

      for (const place of results) {
        if (seenPlaceIds.has(place.place_id)) continue;
        if (pois.length >= maxPois) break;

        seenPlaceIds.add(place.place_id);

        const poi = mapPlaceToPOI(place, city.id);
        if (poi) {
          pois.push(poi);
        }
      }

      if (pois.length >= maxPois) break;

    } catch (error) {
      logger.error(`Failed to search ${type} in ${city.name}:`, error);
    }
  }

  return pois;
}

// ═══════════════════════════════════════════════════════════════════════════
// Map Google Place to POI
// ═══════════════════════════════════════════════════════════════════════════

function mapPlaceToPOI(place: any, cityId: string): POIInput | null {
  // Determine category from types
  const category = determinePOICategory(place.types);

  if (!category) return null;

  // Calculate popularity score
  const popularityScore = calculatePopularityScore(
    place.rating,
    place.user_ratings_total
  );

  return {
    city_id: cityId,
    name: place.name,
    description: place.formatted_address,
    category,
    latitude: place.geometry.location.lat,
    longitude: place.geometry.location.lng,
    address: place.formatted_address,
    rating: place.rating,
    review_count: place.user_ratings_total || 0,
    popularity_score: popularityScore,
    source: 'google_places',
    external_id: place.place_id,
    metadata: {
      opening_hours: place.opening_hours,
      price_level: place.price_level,
      photos: place.photos?.map((p: any) => ({
        reference: p.photo_reference,
      })),
    },
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Determine POI Category
// ═══════════════════════════════════════════════════════════════════════════

function determinePOICategory(types: string[]): POICategory | null {
  for (const type of types) {
    if (PLACE_TYPE_TO_CATEGORY[type]) {
      return PLACE_TYPE_TO_CATEGORY[type];
    }
  }
  return 'other';
}

// ═══════════════════════════════════════════════════════════════════════════
// Calculate Popularity Score
// ═══════════════════════════════════════════════════════════════════════════

function calculatePopularityScore(rating?: number, reviewCount?: number): number {
  let score = 0.3; // Base

  // Rating bonus
  if (rating) {
    if (rating >= 4.5) score += 0.4;
    else if (rating >= 4.0) score += 0.3;
    else if (rating >= 3.5) score += 0.2;
    else score += 0.1;
  }

  // Review count bonus
  if (reviewCount) {
    if (reviewCount >= 1000) score += 0.3;
    else if (reviewCount >= 500) score += 0.2;
    else if (reviewCount >= 100) score += 0.1;
  }

  return Math.min(score, 1.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper: Sleep
// ═══════════════════════════════════════════════════════════════════════════

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  importPOIsForCities({
    limit: undefined, // Только 10 городов для теста
    poisPerCity: 30,
    dryRun: false,
  })
    .then((result) => {
      logger.info('POI import finished', result);
      process.exit(0);
    })
    .catch((error) => {
      logger.error('POI import failed', error);
      process.exit(1);
    });
}

export default importPOIsForCities;

