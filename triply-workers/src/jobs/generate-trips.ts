/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Generate European Trips - Production with DETAILED ITINERARY
 * 🔥 UPDATED: Multiple photos per place (3-5 photos each)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { v4 as uuidv4 } from 'uuid';
import getSupabaseAdmin from '../config/supabase.js';
import openAIService from '../services/openai.service.js';
import hybridImageGalleryService from '../services/hybrid-image-gallery.service.js';
import googlePlacesService from '../services/google-places.service.js';
import logger from '../utils/logger.js';
import config from '../config/env.js';
import type {
  ActivityType,
  TripGenerationParams,
  TripDay,
} from '../models/index.js';

// ═══════════════════════════════════════════════════════════════════════════
// Configuration
// ═══════════════════════════════════════════════════════════════════════════

const EUROPEAN_CITIES_TARGET = [
  // 🎯 TEST PHASE - Top 5 cities
  'Paris',
  'Barcelona',
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
  logger.info('🇪🇺 EUROPEAN TRIP GENERATION (MULTIPLE PHOTOS)');
  logger.info('═══════════════════════════════════════════════════════');
  logger.info(
    `Mode: ${
      testMode ? '🧪 TEST MODE (5 cities)' : '🚀 PRODUCTION (40 cities)'
    }`
  );
  logger.info(`Target cities: ${maxCities}`);
  logger.info(`Activities per city: ${activitiesPerCity}`);
  logger.info(`Features: Detailed places, restaurants, 3-5 photos per place`);
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

  let activities: ActivityType[] = ['city'];

  if (coastalCities.some(c => cityName.includes(c))) {
    activities = ['city', 'beach', 'food'];
  } else if (mountainCities.some(c => cityName.includes(c))) {
    activities = ['city', 'mountains', 'wellness'];
  } else if (majorCapitals.some(c => cityName.includes(c))) {
    activities = ['city', 'cultural', 'food', 'nightlife'];
  } else {
    activities = ['city', 'cultural', 'food'];
  }

  return activities.slice(0, count);
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

  // [1] Fetch POIs
  logger.info(`    [1/7] Fetching POIs...`);

  const { data: pois, error: poisError } = await supabase
    .from('pois')
    .select('*')
    .eq('city_id', params.city_id)
    .order('popularity_score', { ascending: false })
    .limit(params.poi_count);

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

  // [2] Generate itinerary with OpenAI
  logger.info(`    [2/7] Calling OpenAI for DETAILED itinerary...`);

  const tripSkeleton = await openAIService.generateTripSkeleton({
    city: params.city_name,
    country: params.country,
    activity: params.activity_type,
    durationDays: params.duration_days,
    poiList,
  });

  logger.info(`    ✓ Trip skeleton generated with detailed places`);

  // [3] Enrich restaurants with Google Places data
  logger.info(`    [3/7] Enriching restaurants with Google Places data...`);

  await enrichPlacesWithGoogleData(tripSkeleton, params.city_name);

  // [4] Process itinerary
  logger.info(`    [4/7] Processing detailed itinerary...`);

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

  // ✅ Enrich itinerary with MULTIPLE photos per place
  const enrichedItinerary = itineraryDays.map((day, dayIndex) => {
    const dayPlacePhotos = gallery.itineraryImages.get(dayIndex + 1);

    if (!dayPlacePhotos) {
      return { ...day, places: day.places };
    }

    // ✅ Add image_url (first photo) + images[] (all photos) to each place
    const enrichedPlaces = day.places.map((place: any) => {
      const placePhotos = dayPlacePhotos.get(place.name) || [];

      return {
        ...place,
        // ✅ image_url - FIRST photo (for preview cards)
        image_url: placePhotos.length > 0 ? placePhotos[0].url : null,
        // ✅ images - ALL photos (for details screen swipe)
        images: placePhotos.map(p => p.url),
      };
    });

    return {
      ...day,
      places: enrichedPlaces,
      images: Array.from(dayPlacePhotos.values())
        .flat()
        .map(img => img.url),
    };
  });

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
  logger.info('🚀 Starting DETAILED trip generation with MULTIPLE PHOTOS...');

  generateEuropeanTrips({
    testMode: true,
    dryRun: false,
    activitiesPerCity: 2,
    delayBetweenTrips: 3000,
  })
    .then(result => {
      logger.info('🎉 Generation complete!');
      logger.info('Result:', result);
      process.exit(0);
    })
    .catch(error => {
      logger.error('💥 Generation failed');
      logger.error('Error:', error);
      process.exit(1);
    });
}

export default generateEuropeanTrips;
