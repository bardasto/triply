/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Generate European Trips - Production with DETAILED ITINERARY
 * 🔥 UPDATED: Multiple photos per place (3-5 photos each)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { v4 as uuidv4 } from 'uuid';
import getSupabaseAdmin from '../../../shared/config/supabase.js';
import openAIService from '../../ai/services/openai.service.js';
import hybridImageGalleryService from '../../photos/services/hybrid-image-gallery.service.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import config from '../../../shared/config/env.js';
import type {
  ActivityType,
  TripGenerationParams,
  TripDay,
} from '../../../shared/types/index.js';

// Simple logger replacement
const logger = {
  info: (...args: any[]) => console.log('[INFO]', ...args),
  error: (...args: any[]) => console.error('[ERROR]', ...args),
  warn: (...args: any[]) => console.warn('[WARN]', ...args),
};

// ═══════════════════════════════════════════════════════════════════════════
// Configuration
// ═══════════════════════════════════════════════════════════════════════════

const EUROPEAN_CITIES_TARGET = [
  // 🎯 TWO CITIES TEST - Activity-specific prompts test
  'Barcelona',  // Coastal city - beach, cycling, food activities
  'Paris',      // Cultural capital - cultural, shopping, nightlife

  // 🎯 TEST PHASE - Additional cities
  'Amsterdam',
  'Prague',
  'Lisbon',

  // 🚀 PRODUCTION PHASE - Remaining cities
  'London',
  'Edinburgh',
  'Manchester',
  'Liverpool',
  'Nice',
  'Lyon',
  'Marseille',
  'Bordeaux',
  'Strasbourg',
  'Berlin',
  'Munich',
  'Hamburg',
  'Frankfurt',
  'Cologne',
  'Dresden',
  'Rome',
  'Venice',
  'Florence',
  'Milan',
  'Naples',
  'Bologna',
  'Turin',
  'Madrid',
  'Seville',
  'Valencia',
  'Malaga',
  'Granada',
  'Porto',
  'Faro',
  'Rotterdam',
  'Utrecht',
  'Brussels',
  'Bruges',
  'Antwerp',
  'Vienna',
  'Salzburg',
  'Innsbruck',
  'Zurich',
  'Geneva',
  'Lucerne',
  'Budapest',
  'Warsaw',
  'Krakow',
  'Gdansk',
  'Athens',
  'Santorini',
  'Mykonos',
  'Copenhagen',
  'Stockholm',
  'Gothenburg',
  'Oslo',
  'Bergen',
  'Helsinki',
  'Dublin',
  'Cork',
];

const EUROPEAN_ACTIVITIES: ActivityType[] = [
  'city',
  'cultural',
  'food',
  'nightlife',
  'shopping',
  'beach',
  'mountains',
  'wellness',
];

interface PublicTrip {
  id: string;
  title: string;
  description: string;
  duration: string;
  price: string;
  rating: number;
  reviews: number;
  city: string;
  country: string;
  continent: string;
  latitude: number | null;
  longitude: number | null;
  activity_type: ActivityType;
  difficulty_level: string | null;
  best_season: string[];
  includes: string[];
  highlights: string[];
  itinerary: TripDay[];
  images: any[];
  hero_image_url: string | null;
  poi_data: any[];
  attractions: any[];
  estimated_cost_min: number;
  estimated_cost_max: number;
  currency: string;
  generation_id: string;
  relevance_score: number;
  data_sources: Record<string, string>;
  generation_model: string;
  status: 'active' | 'archived' | 'deprecated';
  valid_until: string;
  view_count: number;
  bookmark_count: number;
  share_count: number;
  created_at: string;
  updated_at: string;
}

// ═══════════════════════════════════════════════════════════════════════════
// Main Function: Generate European Trips
// ═══════════════════════════════════════════════════════════════════════════

export async function generateEuropeanTrips(options?: {
  dryRun?: boolean;
  maxCities?: number;
  activitiesPerCity?: number;
  delayBetweenTrips?: number;
  testMode?: boolean;
}) {
  const startTime = Date.now();
  const supabase = getSupabaseAdmin();

  const dryRun = options?.dryRun || false;
  const testMode = options?.testMode !== undefined ? options.testMode : true;
  const maxCities = testMode ? 5 : options?.maxCities || 40;
  const activitiesPerCity = options?.activitiesPerCity || 2;
  const delayMs = options?.delayBetweenTrips || 3000;

  logger.info('═══════════════════════════════════════════════════════');
  logger.info('🇪🇺 TRIP GENERATION WITH ACTIVITY-SPECIFIC PROMPTS');
  logger.info('═══════════════════════════════════════════════════════');
  logger.info(
    `Mode: ${
      testMode ? `🧪 TEST MODE (${maxCities} cities)` : maxCities <= 2 ? '🎯 TWO CITIES TEST' : '🚀 PRODUCTION'
    }`
  );
  logger.info(`Target cities: ${maxCities}`);
  logger.info(`Activities per city: ${activitiesPerCity}`);
  logger.info(`Features: Activity-specific prompts, detailed places, restaurants, 3-5 photos per place`);
  logger.info(
    `Dry run: ${dryRun ? 'YES (no DB writes)' : 'NO (will save to DB)'}`
  );
  logger.info(`Expected trips: ${maxCities * activitiesPerCity}`);
  logger.info(
    `Estimated time: ${(
      (maxCities * activitiesPerCity * delayMs) /
      1000 /
      60
    ).toFixed(1)} minutes`
  );
  logger.info('═══════════════════════════════════════════════════════');

  // 1. Get European cities from database
  logger.info('📍 Fetching European cities from database...');

  const targetCities = EUROPEAN_CITIES_TARGET.slice(0, maxCities);
  logger.info(`Target cities: ${targetCities.join(', ')}`);

  const { data: dbCities, error } = await supabase
    .from('cities')
    .select('*')
    .eq('is_active', true)
    .in('name', targetCities)
    .order('popularity_score', { ascending: false });

  if (error) {
    logger.error('❌ Failed to fetch cities:', error);
    throw error;
  }

  if (!dbCities || dbCities.length === 0) {
    logger.error('❌ No European cities found in database!');
    logger.warn('💡 Make sure cities are seeded first');
    logger.warn('💡 Run: npx tsx src/jobs/seed-cities.ts');
    return {
      citiesProcessed: 0,
      totalTripsGenerated: 0,
      errorCount: 0,
      duration: 0,
    };
  }

  logger.info(`✅ Found ${dbCities.length} European cities in database`);

  // 2. Filter cities with enough POIs
  logger.info('🔍 Checking POI availability for each city...');
  const citiesWithPOIs: any[] = [];

  for (const city of dbCities) {
    const { count } = await supabase
      .from('pois')
      .select('*', { count: 'exact', head: true })
      .eq('city_id', city.id);

    const status = count && count >= 10 ? '✅' : '⚠️';
    logger.info(
      `  ${status} ${city.name}, ${city.country}: ${count || 0} POIs`
    );

    if (count && count >= 10) {
      citiesWithPOIs.push(city);
    } else {
      logger.warn(
        `  ⏭️  Skipping ${city.name} - insufficient POIs (${count || 0})`
      );
    }
  }

  if (citiesWithPOIs.length === 0) {
    logger.error('❌ No cities with sufficient POIs found');
    logger.warn('💡 Need at least 10 POIs per city');
    return {
      citiesProcessed: 0,
      totalTripsGenerated: 0,
      errorCount: 0,
      duration: 0,
    };
  }

  logger.info(`✅ ${citiesWithPOIs.length} cities ready for generation`);
  logger.info('');

  // 3. Generate trips for each city
  const generationId = uuidv4();
  logger.info(`🆔 Generation ID: ${generationId}`);
  logger.info('');

  let totalTripsGenerated = 0;
  let errorCount = 0;

  for (let cityIndex = 0; cityIndex < citiesWithPOIs.length; cityIndex++) {
    const city = citiesWithPOIs[cityIndex];
    const selectedActivities = selectActivitiesForCity(city, activitiesPerCity);

    logger.info('═══════════════════════════════════════════════════════');
    logger.info(
      `🏙️  City ${cityIndex + 1}/${citiesWithPOIs.length}: ${city.name}, ${
        city.country
      }`
    );
    logger.info(`   Activities: ${selectedActivities.join(', ')}`);
    logger.info('═══════════════════════════════════════════════════════');

    // ✅ Track used POIs for this city to ensure diversity across trips
    const usedPOIIds = new Set<string>();

    for (const activity of selectedActivities) {
      try {
        logger.info(`  🎯 Generating ${activity} trip...`);

        const trip = await generateSinglePublicTrip({
          city_id: city.id,
          city_name: city.name,
          country: city.country,
          activity_type: activity,
          duration_days: 3,
          poi_count: 30,
          generation_id: generationId,
          usedPOIIds, // ✅ Pass used POI IDs to avoid repetition
        });

        if (!trip) {
          logger.warn(`  ⚠️  Skipping - no trip generated`);
          continue;
        }

        trip.continent = 'Europe';

        if (!dryRun) {
          await savePublicTrip(trip);
          totalTripsGenerated++;
          logger.info(`  ✅ Saved: ${trip.title}`);
        } else {
          logger.info(`  🔍 DRY RUN: Would save: ${trip.title}`);
          totalTripsGenerated++;
        }

        logger.info(`  ⏳ Waiting ${delayMs / 1000}s before next trip...`);
        await sleep(delayMs);
      } catch (error) {
        logger.error(`  ❌ Failed to generate ${activity} trip`);
        logger.error(`  Error: ${error}`);
        errorCount++;
      }
    }

    logger.info('');
  }

  const duration = Date.now() - startTime;

  logger.info('═══════════════════════════════════════════════════════');
  logger.info('🎉 GENERATION COMPLETE!');
  logger.info('═══════════════════════════════════════════════════════');
  logger.info(`✅ Cities processed: ${citiesWithPOIs.length}`);
  logger.info(`✅ Trips generated: ${totalTripsGenerated}`);
  logger.info(`❌ Errors: ${errorCount}`);
  logger.info(`⏱️  Duration: ${(duration / 1000 / 60).toFixed(1)} minutes`);
  logger.info(
    `📊 Average: ${(duration / totalTripsGenerated / 1000).toFixed(
      1
    )}s per trip`
  );
  logger.info('═══════════════════════════════════════════════════════');

  if (testMode) {
    logger.info('');
    logger.info('💡 TEST MODE COMPLETED SUCCESSFULLY!');
    logger.info('💡 To run full generation (40 cities), use:');
    logger.info('   generateEuropeanTrips({ testMode: false })');
  }

  return {
    citiesProcessed: citiesWithPOIs.length,
    totalTripsGenerated,
    errorCount,
    duration,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Smart Activity Selection
// ═══════════════════════════════════════════════════════════════════════════

function selectActivitiesForCity(city: any, count: number): ActivityType[] {
  const cityName = city.name.toLowerCase();

  // ✅ UPDATED: Enhanced activity selection with 5 activities per city
  const coastalCities = [
    'barcelona',
    'nice',
    'valencia',
    'malaga',
    'lisbon',
    'porto',
    'naples',
    'santorini',
    'mykonos',
    'faro',
    'marseille',
  ];
  const mountainCities = [
    'innsbruck',
    'salzburg',
    'lucerne',
    'geneva',
    'bergen',
  ];
  const majorCapitals = [
    'paris',
    'london',
    'berlin',
    'rome',
    'madrid',
    'amsterdam',
    'vienna',
    'prague',
    'budapest',
  ];

  let activities: ActivityType[] = [];

  // Barcelona - coastal city with diverse activities
  if (cityName.includes('barcelona')) {
    activities = ['city', 'beach', 'food', 'cultural', 'cycling'];
  }
  // Paris - cultural capital
  else if (cityName.includes('paris')) {
    activities = ['city', 'cultural', 'food', 'shopping', 'nightlife'];
  }
  // Other coastal cities
  else if (coastalCities.some(c => cityName.includes(c))) {
    activities = ['city', 'beach', 'food', 'cultural', 'wellness'];
  }
  // Mountain cities
  else if (mountainCities.some(c => cityName.includes(c))) {
    activities = ['city', 'mountains', 'wellness', 'hiking', 'food'];
  }
  // Major capitals
  else if (majorCapitals.some(c => cityName.includes(c))) {
    activities = ['city', 'cultural', 'food', 'nightlife', 'shopping'];
  }
  // Default mix
  else {
    activities = ['city', 'cultural', 'food', 'wellness', 'hiking'];
  }

  return activities.slice(0, count);
}

// ═══════════════════════════════════════════════════════════════════════════
// Get Sort Criteria for Activity Type - Add diversity
// ═══════════════════════════════════════════════════════════════════════════

function getSortCriteriaForActivity(activityType: string): { column: string; ascending: boolean } {
  // ✅ Different sorting for different activities to add diversity
  const sortMap: Record<string, { column: string; ascending: boolean }> = {
    // Popular POIs first for main activities
    city: { column: 'popularity_score', ascending: false },
    cultural: { column: 'popularity_score', ascending: false },

    // Rating-based for food & nightlife (quality over popularity)
    food: { column: 'rating', ascending: false },
    nightlife: { column: 'rating', ascending: false },

    // Mix it up for beach, cycling, shopping - use name to get alphabetical variety
    beach: { column: 'name', ascending: true },
    cycling: { column: 'review_count', ascending: false },
    shopping: { column: 'name', ascending: false },

    // Nature-focused activities - by name for variety
    mountains: { column: 'name', ascending: true },
    hiking: { column: 'name', ascending: false },
    wellness: { column: 'rating', ascending: false },
    skiing: { column: 'review_count', ascending: false },
    sailing: { column: 'name', ascending: true },
  };

  return sortMap[activityType.toLowerCase()] || { column: 'popularity_score', ascending: false };
}

// ═══════════════════════════════════════════════════════════════════════════
// Get Relevant POI Categories for Activity Type
// ═══════════════════════════════════════════════════════════════════════════

function getRelevantPOICategories(activityType: string): string[] {
  // ⚠️ IMPORTANT: These categories MUST match the POICategory enum in src/shared/types/index.ts
  // Valid DB categories: museum, restaurant, landmark, park, beach, shopping, nightlife, cafe, religious, entertainment, nature, other

  const categoryMap: Record<string, string[]> = {
    // Beach activities - coastal and water-related
    beach: ['beach', 'nature', 'park'],

    // Cycling - parks, routes, scenic areas
    cycling: ['park', 'nature', 'landmark'],

    // Mountains - peaks, nature, outdoor
    mountains: ['nature', 'park', 'landmark'],

    // Hiking - trails, nature, outdoor
    hiking: ['nature', 'park'],

    // City - urban landmarks and attractions
    city: ['landmark', 'museum', 'religious', 'park'],

    // Cultural - museums, galleries, heritage
    cultural: ['museum', 'religious', 'landmark', 'entertainment'],

    // Food - restaurants and food markets (mostly restaurants table)
    // ✅ STRICT: Only food-related categories, no landmarks!
    food: ['restaurant', 'cafe'],

    // Shopping - commercial areas
    // ✅ STRICT: Only shopping, no fallback to landmarks
    shopping: ['shopping'],

    // Nightlife - entertainment areas
    // ✅ STRICT: Only nightlife and entertainment, no landmarks
    nightlife: ['nightlife', 'entertainment'],

    // Wellness - peaceful, nature, spa areas
    wellness: ['park', 'nature', 'religious', 'beach'],

    // Skiing - winter sports areas
    skiing: ['nature', 'park', 'entertainment'],

    // Sailing - maritime and coastal
    sailing: ['beach', 'nature', 'landmark'],

    // Desert - arid landscapes
    desert: ['nature', 'park', 'landmark'],

    // Camping - outdoor and nature
    camping: ['nature', 'park'],

    // Road trip - scenic and diverse
    road_trip: ['landmark', 'nature', 'park', 'museum'],
  };

  return categoryMap[activityType.toLowerCase()] || categoryMap['city'];
}

// ═══════════════════════════════════════════════════════════════════════════
// Enrich Places with Google Places Data (Restaurants/Cafes)
// ═══════════════════════════════════════════════════════════════════════════

async function enrichPlacesWithGoogleData(
  tripSkeleton: any,
  cityName: string
): Promise<void> {
  let enrichedCount = 0;
  let totalPlacesWithoutId = 0;
  let skippedPOIs = 0;

  logger.info('    🔍 Enriching restaurants with Google Places data...');

  for (const day of tripSkeleton.itinerary) {
    if (!day.places || !Array.isArray(day.places)) continue;

    for (const place of day.places) {
      // ✅ Skip POIs (already have place_id from database)
      if (place.poi_id) {
        skippedPOIs++;
        logger.info(`      ⏭️  Skipped POI: "${place.name}" (has poi_id)`);
        continue;
      }

      totalPlacesWithoutId++;

      logger.info(`      🔍 Searching for restaurant: "${place.name}" in ${cityName}`);

      try {
        // ✅ Search restaurant/cafe in Google Places
        const googlePlace = await googlePlacesService.findPlaceByName(
          place.name,
          cityName,
          place.latitude && place.longitude
            ? { lat: place.latitude, lng: place.longitude }
            : undefined
        );

        if (googlePlace) {
          place.google_place_id = googlePlace.place_id;
          if (!place.address && googlePlace.address) {
            place.address = googlePlace.address;
          }
          if (!place.rating && googlePlace.rating) {
            place.rating = googlePlace.rating;
          }
          enrichedCount++;
          logger.info(
            `      ✅ Enriched "${place.name}" → ${googlePlace.place_id}`
          );
        } else {
          logger.warn(`      ⚠️  No place_id for "${place.name}" - findPlaceByName returned null`);
        }

        await sleep(300);
      } catch (error) {
        logger.error(`      ❌ Failed to enrich "${place.name}":`, error);
      }
    }
  }

  logger.info(
    `    ✓ Enriched ${enrichedCount}/${totalPlacesWithoutId} restaurants with Google Places data`
  );
  logger.info(`    ℹ️  Skipped ${skippedPOIs} POIs (already have place_id)`);
}

// ═══════════════════════════════════════════════════════════════════════════
// Generate Single Trip with DETAILED ITINERARY + MULTIPLE PHOTOS
// ═══════════════════════════════════════════════════════════════════════════

async function generateSinglePublicTrip(
  params: TripGenerationParams
): Promise<PublicTrip | null> {
  const supabase = getSupabaseAdmin();

  // [1] Fetch POIs (attractions, museums, landmarks) - FILTERED BY ACTIVITY TYPE
  logger.info(`    [1/7] Fetching POIs for ${params.activity_type} activity...`);

  // ✅ Get relevant categories for this activity type
  const relevantCategories = getRelevantPOICategories(params.activity_type);
  logger.info(`    📋 Filtering POIs by categories: ${relevantCategories.slice(0, 5).join(', ')}...`);

  // ✅ Build exclusion filter for already used POIs
  const usedPOIIds = params.usedPOIIds || new Set<string>();
  const usedIdsArray = Array.from(usedPOIIds);

  // ✅ Add diversity in sorting - not always popularity_score
  // For some activities, use different criteria to get unique experiences
  const sortCriteria = getSortCriteriaForActivity(params.activity_type);

  // ✅ Try to fetch POIs matching activity categories first
  let query = supabase
    .from('pois')
    .select('*')
    .eq('city_id', params.city_id)
    .in('category', relevantCategories);

  // ✅ Exclude already used POIs
  if (usedIdsArray.length > 0) {
    query = query.not('id', 'in', `(${usedIdsArray.join(',')})`);
  }

  const { data: categoryPois, error: categoryError } = await query
    .order(sortCriteria.column, { ascending: sortCriteria.ascending })
    .limit(params.poi_count);

  let pois = categoryPois || [];
  const poisError = categoryError;

  // ✅ For strict activity types (food, shopping, nightlife), DO NOT fallback to landmarks
  const strictCategories = ['food', 'shopping', 'nightlife'];
  const allowFallback = !strictCategories.includes(params.activity_type);

  // ✅ If not enough category-specific POIs, supplement with popular ones (only for non-strict types)
  if (pois.length < 10 && allowFallback) {
    logger.warn(`    ⚠️  Only ${pois.length} category-specific POIs found, supplementing with popular ones...`);

    let supplementQuery = supabase
      .from('pois')
      .select('*')
      .eq('city_id', params.city_id)
      .not('id', 'in', `(${[...pois.map(p => p.id), ...usedIdsArray].join(',') || 'none'})`);

    const { data: supplementPois } = await supplementQuery
      .order('popularity_score', { ascending: false })
      .limit(params.poi_count - pois.length);

    if (supplementPois && supplementPois.length > 0) {
      pois = [...pois, ...supplementPois];
    }
  } else if (pois.length < 10 && !allowFallback) {
    logger.warn(`    ⚠️  Only ${pois.length} category-specific POIs found, NOT supplementing (strict category)`);
  }

  logger.info(`    ✓ Fetched ${pois.length} POIs (${categoryPois?.length || 0} category-specific + ${pois.length - (categoryPois?.length || 0)} popular)`);

  // ✅ NEW: Fetch restaurants from database - MORE for food activity
  logger.info(`    [1.5/7] Fetching restaurants from database...`);

  // ✅ Food activity needs MORE restaurants, others need fewer
  const restaurantLimit = params.activity_type === 'food' ? 20 :
                          params.activity_type === 'nightlife' ? 8 :
                          params.activity_type === 'cultural' ? 6 : 10;

  const { data: restaurants, error: restaurantsError } = await supabase
    .from('restaurants')
    .select('*')
    .eq('is_active', true)
    .ilike('address', `%${params.city_name}%`)
    .order('rating', { ascending: false })
    .limit(restaurantLimit);

  if (restaurantsError) {
    logger.warn(`    ⚠️  Error fetching restaurants: ${restaurantsError.message}`);
  } else {
    logger.info(`    ✓ Fetched ${restaurants?.length || 0} restaurants from database (limit: ${restaurantLimit} for ${params.activity_type})`);
  }

  if (poisError || !pois || pois.length < 5) {
    logger.warn(`    ⚠️  Insufficient POIs: ${pois?.length || 0}`);
    return null;
  }

  logger.info(`    ✓ ${pois.length} POIs fetched`);

  // ✅ Extract place_id correctly from external_id or google_place_id
  const poiList = pois.map(poi => ({
    id: poi.id,
    name: poi.name,
    category: poi.category,
    lat: poi.latitude,
    lon: poi.longitude,
    place_id: poi.external_id || poi.google_place_id || '',
  }));

  // ✅ NEW: Convert restaurants from database to list for AI
  // NOTE: We only pass primary_photo to AI to keep prompt size small
  // Full photos array will be added after generation from DB
  // ✅ Sort by rating and limit to top 6 restaurants to reduce prompt size
  const sortedRestaurants = (restaurants || [])
    .sort((a: any, b: any) => {
      const ratingA = a.rating || a.google_rating || 0;
      const ratingB = b.rating || b.google_rating || 0;
      return ratingB - ratingA; // Descending order (highest rating first)
    })
    .slice(0, 6); // ✅ LIMIT to top 6 restaurants

  const restaurantList = sortedRestaurants.map((restaurant: any) => {
    // ✅ Support both Migration 004 VIEW format (image_url) and old format (photos array)
    const primaryPhotoUrl = restaurant.image_url ||
                           restaurant.photos?.find((p: any) => p.is_primary)?.photo_url ||
                           restaurant.photos?.[0]?.photo_url ||
                           restaurant.images?.[0];

    return {
      id: restaurant.id,
      name: restaurant.name,
      cuisine_types: restaurant.cuisine_types || [],
      rating: restaurant.rating || restaurant.google_rating,
      price_level: restaurant.price_level,
      address: restaurant.address,
      lat: restaurant.latitude,
      lon: restaurant.longitude,
      google_place_id: restaurant.google_place_id,
      primary_photo: primaryPhotoUrl,
      description: restaurant.description, // ✅ NEW: Include pre-generated description from DB
      // photos: excluded from AI prompt to reduce size (will be added after from DB)
    };
  });

  logger.info(`    ✓ ${restaurantList.length} restaurants prepared for AI (from ${restaurants?.length || 0} total)`);

  // [2] Generate itinerary with OpenAI
  logger.info(`    [2/7] Calling OpenAI for DETAILED itinerary...`);

  const tripSkeleton = await openAIService.generateTripSkeleton({
    city: params.city_name,
    country: params.country,
    activity: params.activity_type,
    durationDays: params.duration_days,
    poiList,
    restaurantList, // ✅ NEW: Pass restaurants from database
  });

  logger.info(`    ✓ Trip skeleton generated with detailed places`);

  // [3] Fill restaurant photos from database
  logger.info(`    [3/7] Filling restaurant photos from database...`);

  // Create a map of restaurant ID -> photos for quick lookup
  const restaurantPhotosMap = new Map();
  (restaurants || []).forEach((restaurant: any) => {
    // ✅ Support both Migration 004 VIEW format (images array) and old format (photos JSONB)
    let photoUrls: string[] = [];

    if (restaurant.images && Array.isArray(restaurant.images) && restaurant.images.length > 0) {
      // Migration 004 VIEW format - images is TEXT[] of URLs
      photoUrls = restaurant.images;
    } else if (restaurant.photos && Array.isArray(restaurant.photos) && restaurant.photos.length > 0) {
      // Old format - photos is JSONB array of objects with photo_url
      photoUrls = restaurant.photos.map((p: any) => p.photo_url);
    }

    if (photoUrls.length > 0) {
      logger.info(`      Restaurant ID ${restaurant.id} (${restaurant.name}): ${photoUrls.length} photos`);
      restaurantPhotosMap.set(restaurant.id, photoUrls);
    }
  });

  logger.info(`    ✓ Built photo map with ${restaurantPhotosMap.size} restaurants`);

  // Fill photos for each restaurant in itinerary
  let photosFilledCount = 0;
  for (const day of tripSkeleton.itinerary) {
    for (const place of day.places || []) {
      // Check if this is a restaurant (has category breakfast/lunch/dinner)
      const isRestaurant = ['breakfast', 'lunch', 'dinner'].includes(place.category);

      if (isRestaurant) {
        // ✅ Support both poi_id (new) and id (legacy) fields
        const restaurantId = (place as any).poi_id || (place as any).id;
        logger.info(`      Checking restaurant "${place.name}": poi_id=${restaurantId}, category=${place.category}`);

        // Check if this restaurant has photos in our map
        if (restaurantId && restaurantPhotosMap.has(restaurantId)) {
          place.images = restaurantPhotosMap.get(restaurantId);
          photosFilledCount++;
          logger.info(`        ✓ Found ${place.images.length} photos for ${place.name}`);
        } else {
          logger.warn(`        ❌ No photos found for ${place.name} (id: ${restaurantId})`);
          logger.warn(`           Available IDs in map: ${Array.from(restaurantPhotosMap.keys()).join(', ')}`);
        }
      }
    }
  }

  logger.info(`    ✓ Filled photos for ${photosFilledCount} restaurants from database`);

  const itineraryDays: TripDay[] = tripSkeleton.itinerary.map((day: any) => ({
    day: day.day,
    title: day.title,
    description: day.description,
    places: day.places || [],
    images: day.images || [],
  }));

  const totalPlaces = itineraryDays.reduce(
    (sum: number, day: any) => sum + (day.places?.length || 0),
    0
  );

  logger.info(
    `    ✓ ${itineraryDays.length} days with ${totalPlaces} total places`
  );

  // [5] Fetch images (Hero: Unsplash, Multiple photos per place: Google)
  logger.info(
    `    [5/7] Fetching multiple photos per place (3 photos each)...`
  );

  const itineraryForImages = itineraryDays.map((day, dayIndex) => {
    const mappedPlaces = (day.places || []).map((p: any) => {
      // POI: use external_id from database
      if (p.poi_id) {
        const poi = pois.find(poi => poi.id === p.poi_id);
        const placeId = poi?.external_id || poi?.google_place_id || '';

        logger.info(`    [Day ${dayIndex + 1}] POI "${p.name}": poi_id=${p.poi_id}, place_id=${placeId || 'EMPTY'}`);

        return {
          place_id: placeId,
          name: p.name,
        };
      }

      // Restaurant: use google_place_id from enrichment
      const googlePlaceId = p.google_place_id || '';

      logger.info(`    [Day ${dayIndex + 1}] Restaurant "${p.name}": google_place_id=${googlePlaceId || 'EMPTY'}`);

      return {
        google_place_id: googlePlaceId,
        name: p.name,
        place_id: '',
      };
    });

    const filteredPlaces = mappedPlaces.filter((p: any) => p.place_id || p.google_place_id);

    logger.info(`    [Day ${dayIndex + 1}] Total places: ${day.places?.length || 0}, After filter: ${filteredPlaces.length}`);

    return {
      title: day.title,
      pois: filteredPlaces,
    };
  });

  const gallery = await hybridImageGalleryService.getCompleteTripGallery(
    params.city_name,
    params.activity_type,
    itineraryForImages
  );

  const totalGooglePhotos =
    Array.from(gallery.itineraryImages.values())
      .flatMap(dayMap => Array.from(dayMap.values()))
      .flat().length + gallery.cityGallery.length;

  logger.info(
    `    ✓ Gallery complete:\n` +
      `       - Hero: ${!!gallery.heroImage ? 'Unsplash ✓' : 'none'}\n` +
      `       - Google Places photos: ${totalGooglePhotos}`
  );

  // [6] Fetch coordinates
  logger.info(`    [6/7] Fetching coordinates...`);

  const { data: city } = await supabase
    .from('cities')
    .select('latitude, longitude')
    .eq('id', params.city_id)
    .single();

  // [7] Build trip object with MULTIPLE PHOTOS per place
  logger.info(`    [7/7] Building trip object with multiple photos...`);

  // Build comprehensive images array
  const allImages: any[] = [];

  if (gallery.heroImage) {
    allImages.push({ ...gallery.heroImage, type: 'hero', order: 0 });
  }

  gallery.cityGallery.forEach((img, index) => {
    allImages.push({ ...img, type: 'city_gallery', order: index + 1 });
  });

  let orderCounter = allImages.length;

  // ✅ Save ALL photos with place name mapping
  gallery.itineraryImages.forEach((dayPlacePhotos, dayNumber) => {
    dayPlacePhotos.forEach((photos, placeName) => {
      photos.forEach((img, photoIndex) => {
        allImages.push({
          ...img,
          type: 'itinerary',
          day: dayNumber,
          place_name: placeName, // ✅ Link photo → place
          photo_index: photoIndex, // ✅ Photo order (0, 1, 2)
          order: orderCounter++,
        });
      });
    });
  });

  // ✅ Enrich itinerary with MULTIPLE photos per place + opening_hours from database
  const enrichedItinerary = await Promise.all(
    itineraryDays.map(async (day, dayIndex) => {
      const dayPlacePhotos = gallery.itineraryImages.get(dayIndex + 1);

      // ✅ Add image_url (first photo) + images[] (all photos) + opening_hours to each place
      const enrichedPlaces = await Promise.all(
        day.places.map(async (place: any) => {
          const placePhotos = dayPlacePhotos?.get(place.name) || [];

          // ✅ Fetch opening_hours from database if place has poi_id
          let openingHours = place.opening_hours; // Keep existing if any
          if (place.poi_id && !openingHours) {
            try {
              // Try to get from POIs table first
              const { data: poiData } = await supabase
                .from('pois')
                .select('metadata')
                .eq('id', place.poi_id)
                .single();

              if (poiData?.metadata?.opening_hours) {
                openingHours = poiData.metadata.opening_hours;
              } else {
                // Try restaurants table
                const { data: restaurantData } = await supabase
                  .from('restaurants')
                  .select('opening_hours')
                  .eq('id', place.poi_id)
                  .single();

                if (restaurantData?.opening_hours) {
                  openingHours = restaurantData.opening_hours;
                }
              }
            } catch (err) {
              // Silently fail if place not found in database
              logger.debug(`Could not fetch opening_hours for ${place.name}`);
            }
          }

          return {
            ...place,
            // ✅ image_url - Keep existing (from database) or use first Google photo
            image_url: place.image_url || (placePhotos.length > 0 ? placePhotos[0].url : null),
            // ✅ images - Keep existing (from database) or use all Google photos
            images: place.images && place.images.length > 0
              ? place.images
              : placePhotos.map(p => p.url),
            // ✅ opening_hours - From database (full Google Places format)
            opening_hours: openingHours || null,
          };
        })
      );

      return {
        ...day,
        places: enrichedPlaces,
        images: dayPlacePhotos
          ? Array.from(dayPlacePhotos.values())
              .flat()
              .map(img => img.url)
          : [],
      };
    })
  );

  const trip: PublicTrip = {
    id: uuidv4(),
    title: tripSkeleton.title,
    description: tripSkeleton.description,
    duration: tripSkeleton.duration || `${params.duration_days} days`,
    price: `€${tripSkeleton.recommendedBudget?.min || 500}`,
    rating: 4.5,
    reviews: 0,

    city: params.city_name,
    country: params.country,
    continent: 'Europe',
    latitude: city?.latitude || null,
    longitude: city?.longitude || null,

    activity_type: params.activity_type,
    difficulty_level: null,
    best_season: tripSkeleton.bestSeasons || ['spring', 'autumn'],

    includes: tripSkeleton.includes || [],
    highlights: tripSkeleton.highlights || [],
    itinerary: enrichedItinerary, // ✅ With multiple photos

    images: allImages,
    hero_image_url: gallery.heroImage?.url || null,

    poi_data: poiList.map(poi => ({
      poi_id: poi.id,
      name: poi.name,
      category: poi.category,
      latitude: poi.lat,
      longitude: poi.lon,
      snapshot_at: new Date().toISOString(),
    })),
    attractions: [],

    estimated_cost_min: tripSkeleton.recommendedBudget?.min || 150,
    estimated_cost_max: tripSkeleton.recommendedBudget?.max || 450,
    currency: 'EUR',

    generation_id: params.generation_id,
    relevance_score: 0.8,
    data_sources: {
      places: 'google_places',
      ai: 'openai',
      images: 'unsplash_hero+google_places_multiple', // ✅ Updated
      itinerary: 'openai_detailed',
    },
    generation_model: config.OPENAI_MODEL,

    status: 'active',
    valid_until: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
    view_count: 0,
    bookmark_count: 0,
    share_count: 0,

    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  const googlePhotosCount = allImages.filter(
    img => img.source === 'google_places'
  ).length;

  logger.info(
    `    ✅ Trip complete: ${trip.title}\n` +
      `       📸 Total images: ${allImages.length}\n` +
      `       🖼️  Google Places photos: ${googlePhotosCount}\n` +
      `       🏛️  Places with real photos: ${totalPlaces} (3-5 each)`
  );

  // ✅ Mark POIs as used to ensure diversity in next trips for this city
  if (params.usedPOIIds) {
    pois.forEach(poi => params.usedPOIIds!.add(poi.id));
    logger.info(`    ✓ Marked ${pois.length} POIs as used for this city`);
  }

  return trip;
}

async function savePublicTrip(trip: PublicTrip): Promise<void> {
  const supabase = getSupabaseAdmin();
  const { error } = await supabase.from('public_trips').insert(trip);

  if (error) {
    logger.error('❌ Save failed:', error);
    throw new Error(`Failed to save: ${error.message}`);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  logger.info('🚀 Starting DETAILED trip generation with ACTIVITY-SPECIFIC PROMPTS...');
  logger.info('🎯 TWO CITIES TEST: Barcelona & Paris with 5 activities each');
  logger.info('');

  generateEuropeanTrips({
    testMode: false,           // Use custom maxCities instead
    maxCities: 2,              // ✅ Only Barcelona and Paris
    activitiesPerCity: 5,      // ✅ 5 different activities per city
    dryRun: false,             // ✅ Real generation (will save to DB)
    delayBetweenTrips: 3000,   // 3 seconds between trips
  })
    .then(result => {
      logger.info('');
      logger.info('🎉 Generation complete!');
      logger.info('Result:', result);
      logger.info('');
      logger.info('📊 Expected results:');
      logger.info('   - Barcelona: 5 trips (city, beach, food, cultural, cycling)');
      logger.info('   - Paris: 5 trips (city, cultural, food, shopping, nightlife)');
      logger.info('   - Total: 10 trips with activity-specific prompts');
      process.exit(0);
    })
    .catch(error => {
      logger.error('');
      logger.error('💥 Generation failed');
      logger.error('Error:', error);
      process.exit(1);
    });
}

export default generateEuropeanTrips;
