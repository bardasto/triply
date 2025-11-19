/**
 * ═══════════════════════════════════════════════════════════════════════════
 * HYBRID TRIP GENERATION V2 - Separated Restaurants
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ✅ AI Freedom: AI generates places freely
 * ✅ Separated Structure: places[] and restaurants[] are separate arrays
 * ✅ Cache Optimization: Uses cached restaurants when available
 * ✅ Photo Strategy: Cache first, then Google Places API
 * ✅ High Quality: Activity-specific prompts + restaurant suggestions
 */

import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';
import { getActivityPrompt } from './src/modules/ai/prompts/activity-prompts.js';
import googlePlacesService from './src/modules/google-places/services/google-places.service.js';
import googlePlacesPhotosService from './src/modules/google-places/services/google-places-photos.service.js';
import OpenAI from 'openai';

// ═══════════════════════════════════════════════════════════════════════════
// Configuration
// ═══════════════════════════════════════════════════════════════════════════

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const supabase = getSupabaseAdmin();

// Target cities with coordinates
const TARGET_CITIES = [
  {
    name: 'Barcelona',
    country: 'Spain',
    id: 'd0045c38-048f-4f44-976f-c91b94d2b900',
    lat: 41.3851,
    lng: 2.1734,
    activities: ['city', 'beach', 'food', 'cultural', 'cycling']
  },
  {
    name: 'Paris',
    country: 'France',
    id: '56501812-c4a4-4840-80c6-3ce6ef0a9d6e',
    lat: 48.8566,
    lng: 2.3522,
    activities: ['city', 'cultural', 'food', 'shopping', 'nightlife']
  },
];

// ═══════════════════════════════════════════════════════════════════════════
// Fetch Cached Restaurants for City
// ═══════════════════════════════════════════════════════════════════════════

async function getCachedRestaurants(cityName: string, limit: number = 15) {
  logger.info(`  📦 Fetching cached restaurants for ${cityName}...`);

  const { data: restaurants, error } = await supabase
    .from('restaurants')
    .select('*')
    .eq('is_active', true)
    .ilike('address', `%${cityName}%`)
    .order('rating', { ascending: false })
    .limit(limit);

  if (error) {
    logger.warn(`  ⚠️  Error fetching cached restaurants: ${error.message}`);
    return [];
  }

  logger.info(`  ✓ Found ${restaurants?.length || 0} cached restaurants`);
  return restaurants || [];
}

// ═══════════════════════════════════════════════════════════════════════════
// Build Enhanced Prompt with Restaurant Suggestions
// ═══════════════════════════════════════════════════════════════════════════

function buildEnhancedPrompt(
  city: string,
  country: string,
  activity: string,
  durationDays: number,
  cachedRestaurants: any[]
): string {
  const basePrompt = getActivityPrompt({
    city,
    country,
    activity,
    durationDays,
    language: 'English'
  });

  if (!cachedRestaurants || cachedRestaurants.length === 0) {
    return basePrompt;
  }

  const restaurantSuggestions = cachedRestaurants
    .slice(0, 10)
    .map(r => `- ${r.name} (${r.cuisine_types?.join(', ') || 'Restaurant'}) - Rating: ${r.rating || 'N/A'}, ${r.address}`)
    .join('\n');

  const enhancedPrompt = `${basePrompt}

🍽️ SUGGESTED RESTAURANTS (use these in "restaurants" array):
We have high-quality cached data for these restaurants in ${city}.
PREFER these restaurants in your "restaurants" array for better data quality:

${restaurantSuggestions}

IMPORTANT:
- Include 2-3 of these in your "restaurants" array per day
- These go in the "restaurants" array, NOT in "places" array
- Category should be: "breakfast", "lunch", or "dinner"`;

  return enhancedPrompt;
}

// ═══════════════════════════════════════════════════════════════════════════
// Get Hero Image
// ═══════════════════════════════════════════════════════════════════════════

async function getHeroImageFromGooglePlaces(
  activity: string,
  city: string,
  coordinates: { lat: number; lng: number }
): Promise<string | null> {
  try {
    const searchQuery = `${activity} ${city}`;
    logger.info(`  🔍 Searching for hero image: "${searchQuery}"`);

    const results = await googlePlacesService.textSearch({
      query: searchQuery,
      location: coordinates,
      radius: 50000,
    });

    if (results.length === 0) return null;

    const firstPlace = results[0];
    if (!firstPlace.place_id) return null;

    const photos = await googlePlacesPhotosService.getPOIPhotos(
      firstPlace.place_id,
      1
    );

    if (photos.length > 0) {
      logger.info(`  ✓ Hero image from: ${firstPlace.name}`);
      return photos[0].url;
    }

    return null;
  } catch (error: any) {
    logger.error(`  ❌ Hero image error:`, error.message);
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Enrich Place/Restaurant with Photos (Cache First)
// ═══════════════════════════════════════════════════════════════════════════

async function enrichWithPhotos(
  item: any,
  cachedRestaurants: any[],
  cityName: string,
  coordinates: { lat: number; lng: number },
  isRestaurant: boolean = false
): Promise<boolean> {
  // Step 1: Check cache
  const cached = cachedRestaurants.find(
    r => r.name.toLowerCase() === item.name.toLowerCase()
  );

  if (cached && cached.images?.length > 0) {
    logger.info(`    ✓ Cache hit: "${item.name}" (${cached.images.length} photos)`);
    item.images = cached.images.map((url: string) => ({
      url,
      source: 'cache',
      alt_text: `${item.name}`,
    }));
    item.rating = cached.rating || item.rating;
    item.address = cached.address || item.address;
    item.opening_hours = cached.opening_hours;
    return true; // From cache
  }

  // Step 2: Google Places API
  try {
    logger.info(`    🔍 Google search: "${item.name}"`);

    const searchQuery = `${item.name} ${item.address || cityName}`;
    const results = await googlePlacesService.textSearch({
      query: searchQuery,
      location: { lat: item.latitude || coordinates.lat, lng: item.longitude || coordinates.lng },
      radius: 1000,
    });

    if (results.length > 0 && results[0].place_id) {
      const photos = await googlePlacesPhotosService.getPOIPhotos(
        results[0].place_id,
        12
      );

      if (photos.length > 0) {
        item.images = photos.map((p) => ({
          url: p.url,
          source: 'google_places',
          alt_text: `${item.name}`,
        }));
        logger.info(`    ✓ Google: "${item.name}" (${photos.length} photos)`);
        return false; // From Google
      }
    }

    logger.warn(`    ⚠️  No photos: "${item.name}"`);
    item.images = [];
    return false;
  } catch (error: any) {
    logger.error(`    ❌ Error: "${item.name}": ${error.message}`);
    item.images = [];
    return false;
  } finally {
    await sleep(300);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Generate Single Trip
// ═══════════════════════════════════════════════════════════════════════════

async function generateHybridTrip(
  city: any,
  activity: string,
  durationDays: number
): Promise<any | null> {
  try {
    logger.info(`  🎯 Generating ${activity} trip for ${city.name}...`);

    // Step 1: Fetch cached restaurants
    const cachedRestaurants = await getCachedRestaurants(city.name, 15);

    // Step 2: Build enhanced prompt
    logger.info(`  📝 Building enhanced prompt...`);
    const prompt = buildEnhancedPrompt(
      city.name,
      city.country,
      activity,
      durationDays,
      cachedRestaurants
    );

    // Step 3: Call OpenAI
    logger.info(`  🤖 Calling OpenAI...`);
    const completion = await openai.chat.completions.create({
      model: 'gpt-4-turbo-preview',
      messages: [
        {
          role: 'system',
          content: 'You are a travel expert. Create detailed itineraries with separated places and restaurants arrays. Always output valid JSON.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.8,
      response_format: { type: 'json_object' },
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No content in OpenAI response');
    }

    const tripData = JSON.parse(content);
    logger.info(`  ✓ Generated: "${tripData.title}"`);

    // Count places and restaurants
    const totalPlaces = tripData.itinerary?.reduce(
      (sum: number, day: any) => sum + (day.places?.length || 0),
      0
    );
    const totalRestaurants = tripData.itinerary?.reduce(
      (sum: number, day: any) => sum + (day.restaurants?.length || 0),
      0
    );
    logger.info(`  ✓ Places: ${totalPlaces}, Restaurants: ${totalRestaurants}`);

    // Step 4: Get hero image
    logger.info(`  🖼️  Fetching hero image...`);
    const heroImage = await getHeroImageFromGooglePlaces(
      activity,
      city.name,
      { lat: city.lat, lng: city.lng }
    );

    // Step 5: Enrich all places and restaurants with photos
    logger.info(`  📸 Enriching with photos...`);
    let placesFromCache = 0;
    let placesFromGoogle = 0;
    let restaurantsFromCache = 0;
    let restaurantsFromGoogle = 0;

    for (const day of tripData.itinerary || []) {
      // Enrich places (attractions, museums, NOT restaurants)
      for (const place of day.places || []) {
        const fromCache = await enrichWithPhotos(place, cachedRestaurants, city.name, { lat: city.lat, lng: city.lng }, false);
        if (fromCache) placesFromCache++;
        else if (place.images?.length > 0) placesFromGoogle++;
      }

      // Enrich restaurants separately
      for (const restaurant of day.restaurants || []) {
        const fromCache = await enrichWithPhotos(restaurant, cachedRestaurants, city.name, { lat: city.lat, lng: city.lng }, true);
        if (fromCache) restaurantsFromCache++;
        else if (restaurant.images?.length > 0) restaurantsFromGoogle++;
      }
    }

    logger.info(`  📊 Places: ${placesFromCache} cache + ${placesFromGoogle} Google`);
    logger.info(`  📊 Restaurants: ${restaurantsFromCache} cache + ${restaurantsFromGoogle} Google`);

    // Step 6: Save to database
    logger.info(`  💾 Saving...`);

    const budget = tripData.recommendedBudget || { min: 150, max: 400, currency: 'EUR' };

    const { data: insertedTrip, error: insertError } = await supabase
      .from('public_trips')
      .insert({
        id: crypto.randomUUID(),
        city: city.name,
        country: city.country,
        continent: 'Europe',
        title: tripData.title,
        description: tripData.description,
        duration: tripData.duration || `${durationDays} days`,
        price: '€€€',
        rating: 4.5 + Math.random() * 0.5,
        reviews: Math.floor(Math.random() * 500) + 100,
        latitude: city.lat,
        longitude: city.lng,
        activity_type: activity,
        difficulty_level: 'moderate',
        best_season: tripData.bestSeasons || ['spring', 'summer'],
        includes: tripData.includes || [],
        highlights: tripData.highlights || [],
        itinerary: tripData.itinerary, // ✅ Now with separated places and restaurants
        images: [],
        hero_image_url: heroImage,
        poi_data: [],
        attractions: [],
        estimated_cost_min: budget.min,
        estimated_cost_max: budget.max,
        currency: budget.currency || 'EUR',
        generation_id: crypto.randomUUID(),
        relevance_score: 0.9 + Math.random() * 0.1,
        data_sources: {
          structure: 'separated_places_restaurants_v2',
          pois: 'ai_generated',
          itinerary: 'openai_gpt4_hybrid_v2',
          hero_image: 'google_places',
          photos: `places_cache_${placesFromCache}_google_${placesFromGoogle}_restaurants_cache_${restaurantsFromCache}_google_${restaurantsFromGoogle}`,
        },
        generation_model: 'gpt-4-turbo-preview-hybrid-v2',
        status: 'active',
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Database error: ${insertError.message}`);
    }

    logger.info(`  ✅ SUCCESS (ID: ${insertedTrip.id})`);
    return insertedTrip;
  } catch (error: any) {
    logger.error(`  ❌ FAILED: ${error.message}`);
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Main Function
// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  const startTime = Date.now();

  logger.info('═══════════════════════════════════════════════════════════════');
  logger.info('🚀 HYBRID TRIP GENERATION V2 - Separated Restaurants');
  logger.info('═══════════════════════════════════════════════════════════════');
  logger.info('✅ Separated Structure: places[] and restaurants[] arrays');
  logger.info('✅ Cache Optimization: Uses cached restaurants');
  logger.info('✅ Photo Strategy: Cache first, then Google Places');
  logger.info('═══════════════════════════════════════════════════════════════\n');

  // Delete old trips
  logger.info('🗑️  Deleting old trips...');
  await supabase
    .from('public_trips')
    .delete()
    .in('city', ['Barcelona', 'Paris']);
  logger.info('✅ Old trips deleted\n');

  // Generate trips
  let successCount = 0;
  let failCount = 0;

  for (const city of TARGET_CITIES) {
    logger.info(`\n${'═'.repeat(60)}`);
    logger.info(`🏙️  CITY: ${city.name}, ${city.country}`);
    logger.info(`${'═'.repeat(60)}\n`);

    for (const activity of city.activities) {
      const tripResult = await generateHybridTrip(city, activity, 3);

      if (tripResult) {
        successCount++;
      } else {
        failCount++;
      }

      logger.info(`  ⏳ Waiting 2s...\n`);
      await sleep(2000);
    }
  }

  // Summary
  const duration = (Date.now() - startTime) / 1000;
  const total = TARGET_CITIES.reduce((sum, c) => sum + c.activities.length, 0);

  logger.info('\n═══════════════════════════════════════════════════════════════');
  logger.info('📊 SUMMARY');
  logger.info('═══════════════════════════════════════════════════════════════');
  logger.info(`✅ Success: ${successCount}/${total}`);
  logger.info(`❌ Failed: ${failCount}`);
  logger.info(`⏱️  Duration: ${duration.toFixed(2)}s`);
  logger.info('═══════════════════════════════════════════════════════════════\n');

  if (successCount === total) {
    logger.info('🎉 ALL TRIPS GENERATED!');
  }

  process.exit(0);
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

main().catch((error) => {
  logger.error('❌ Fatal error:', error);
  process.exit(1);
});
