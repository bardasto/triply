/**
 * ═══════════════════════════════════════════════════════════════════════════
 * HYBRID TRIP GENERATION - Best of Both Worlds
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ✅ AI Freedom: AI generates places freely (like generate-barcelona-all-activities.ts)
 * ✅ Cache Optimization: Uses cached restaurants when available (Google compliance)
 * ✅ Photo Strategy: Cache first, then Google Places API
 * ✅ High Quality: Activity-specific prompts + restaurant suggestions
 * ✅ No POI Limitations: No strict category filtering, always succeeds
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
  // Get base activity prompt
  const basePrompt = getActivityPrompt({
    city,
    country,
    activity,
    durationDays,
    language: 'English'
  });

  // If no cached restaurants, return base prompt
  if (!cachedRestaurants || cachedRestaurants.length === 0) {
    return basePrompt;
  }

  // Build restaurant suggestions section
  const restaurantSuggestions = cachedRestaurants
    .slice(0, 10) // Top 10 restaurants
    .map(r => `- ${r.name} (${r.cuisine_types?.join(', ') || 'Restaurant'}) - Rating: ${r.rating || 'N/A'}, ${r.address}`)
    .join('\n');

  // Add restaurant suggestions to prompt
  const enhancedPrompt = `${basePrompt}

🍽️ CACHED RESTAURANT SUGGESTIONS (OPTIONAL):
We have high-quality cached data for these restaurants in ${city}.
You MAY include some of these in your itinerary if they fit the ${activity} activity:

${restaurantSuggestions}

IMPORTANT:
- These are OPTIONAL suggestions - feel free to use other restaurants too
- Only include them if they fit naturally into the ${activity} itinerary
- You can also suggest other restaurants you know about
- Prioritize variety and authentic local dining experiences`;

  return enhancedPrompt;
}

// ═══════════════════════════════════════════════════════════════════════════
// Get Hero Image from Google Places
// ═══════════════════════════════════════════════════════════════════════════

async function getHeroImageFromGooglePlaces(
  tripTitle: string,
  activity: string,
  city: string,
  coordinates: { lat: number; lng: number }
): Promise<string | null> {
  try {
    const searchQuery = `${activity} ${city}`;
    logger.info(`  🔍 Searching Google Places for hero image: "${searchQuery}"`);

    const results = await googlePlacesService.textSearch({
      query: searchQuery,
      location: coordinates,
      radius: 50000,
    });

    if (results.length === 0) {
      logger.warn(`  ⚠️  No places found for hero image`);
      return null;
    }

    const firstPlace = results[0];
    logger.info(`  ✓ Found place: ${firstPlace.name}`);

    if (!firstPlace.place_id) {
      return null;
    }

    const photos = await googlePlacesPhotosService.getPOIPhotos(
      firstPlace.place_id,
      1
    );

    if (photos.length > 0) {
      logger.info(`  ✓ Got hero image from: ${firstPlace.name}`);
      return photos[0].url;
    }

    return null;
  } catch (error: any) {
    logger.error(`  ❌ Failed to get hero image:`, error.message);
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Enrich Place with Photos (Cache First, then Google Places)
// ═══════════════════════════════════════════════════════════════════════════

async function enrichPlaceWithPhotos(
  place: any,
  cachedRestaurants: any[],
  cityName: string,
  coordinates: { lat: number; lng: number }
): Promise<void> {
  // Step 1: Check if this place is in our cached restaurants
  const cachedRestaurant = cachedRestaurants.find(
    r => r.name.toLowerCase() === place.name.toLowerCase()
  );

  if (cachedRestaurant && cachedRestaurant.images?.length > 0) {
    logger.info(`    ✓ Using cached photos for "${place.name}" (${cachedRestaurant.images.length} photos)`);
    place.images = cachedRestaurant.images.map((url: string) => ({
      url,
      source: 'cache',
      alt_text: `${place.name} - ${place.type}`,
    }));
    place.rating = cachedRestaurant.rating || place.rating;
    place.address = cachedRestaurant.address || place.address;
    place.opening_hours = cachedRestaurant.opening_hours;
    return;
  }

  // Step 2: Not in cache, search Google Places
  try {
    logger.info(`    🔍 Searching Google Places for: "${place.name}"`);

    const searchQuery = `${place.name} ${place.address || cityName}`;
    const results = await googlePlacesService.textSearch({
      query: searchQuery,
      location: { lat: place.latitude || coordinates.lat, lng: place.longitude || coordinates.lng },
      radius: 1000,
    });

    if (results.length > 0 && results[0].place_id) {
      // Get 10-12 photos from Google Places
      const photos = await googlePlacesPhotosService.getPOIPhotos(
        results[0].place_id,
        12
      );

      if (photos.length > 0) {
        place.images = photos.map((p) => ({
          url: p.url,
          source: 'google_places',
          alt_text: `${place.name} - ${place.type}`,
        }));
        logger.info(`    ✓ Got ${photos.length} photos from Google Places for "${place.name}"`);
      } else {
        logger.warn(`    ⚠️  No photos found for "${place.name}"`);
        place.images = [];
      }
    } else {
      logger.warn(`    ⚠️  Place not found in Google: "${place.name}"`);
      place.images = [];
    }

    // Small delay to avoid rate limiting
    await sleep(300);
  } catch (error: any) {
    logger.error(`    ❌ Error fetching photos for "${place.name}": ${error.message}`);
    place.images = [];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Generate Single Trip with Hybrid Approach
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

    // Step 2: Build enhanced prompt with restaurant suggestions
    logger.info(`  📝 Building enhanced AI prompt...`);
    const prompt = buildEnhancedPrompt(
      city.name,
      city.country,
      activity,
      durationDays,
      cachedRestaurants
    );

    // Step 3: Call OpenAI to generate trip
    logger.info(`  🤖 Calling OpenAI with enhanced prompt...`);
    const completion = await openai.chat.completions.create({
      model: 'gpt-4-turbo-preview',
      messages: [
        {
          role: 'system',
          content: 'You are a travel expert who creates detailed, authentic trip itineraries with REAL specific places. Always output valid JSON.',
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
    logger.info(`  ✓ Generated trip: "${tripData.title}"`);

    // Count total places
    const totalPlaces = tripData.itinerary?.reduce(
      (sum: number, day: any) => sum + (day.places?.length || 0),
      0
    );
    logger.info(`  ✓ Days: ${tripData.itinerary?.length || 0}, Total places: ${totalPlaces}`);

    // Step 4: Get hero image
    logger.info(`  🖼️  Fetching hero image...`);
    const heroImage = await getHeroImageFromGooglePlaces(
      tripData.title,
      activity,
      city.name,
      { lat: city.lat, lng: city.lng }
    );

    if (heroImage) {
      logger.info(`  ✓ Hero image obtained`);
    }

    // Step 5: Enrich all places with photos (cache first, then Google Places)
    logger.info(`  📸 Enriching places with photos...`);
    let totalPhotos = 0;
    let cacheHits = 0;
    let googleHits = 0;

    for (const day of tripData.itinerary || []) {
      for (const place of day.places || []) {
        const photosBefore = place.images?.length || 0;
        await enrichPlaceWithPhotos(place, cachedRestaurants, city.name, { lat: city.lat, lng: city.lng });
        const photosAfter = place.images?.length || 0;

        if (photosAfter > photosBefore) {
          totalPhotos += photosAfter;
          if (place.images[0]?.source === 'cache') {
            cacheHits++;
          } else {
            googleHits++;
          }
        }
      }
    }

    logger.info(`  📊 Photos: ${totalPhotos} total (${cacheHits} from cache, ${googleHits} from Google Places)`);

    // Step 6: Save to database
    logger.info(`  💾 Saving to database...`);

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
        itinerary: tripData.itinerary,
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
          pois: 'ai_generated',
          itinerary: 'openai_gpt4_hybrid',
          hero_image: 'google_places',
          photos: `cache_${cacheHits}_google_${googleHits}`,
        },
        generation_model: 'gpt-4-turbo-preview-hybrid',
        status: 'active',
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Database insert error: ${insertError.message}`);
    }

    logger.info(`  ✅ SUCCESS: Trip saved (ID: ${insertedTrip.id})`);
    return insertedTrip;
  } catch (error: any) {
    logger.error(`  ❌ FAILED: ${error.message}`);
    if (error.message.includes('Unterminated string')) {
      logger.error(`  🔍 JSON parsing error - OpenAI response was malformed`);
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Main Function
// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  const startTime = Date.now();

  logger.info('═══════════════════════════════════════════════════════════════');
  logger.info('🚀 HYBRID TRIP GENERATION - Best of Both Worlds');
  logger.info('═══════════════════════════════════════════════════════════════');
  logger.info('✅ AI Freedom: Full creative control');
  logger.info('✅ Cache Optimization: Uses cached restaurants when available');
  logger.info('✅ Photo Strategy: Cache first, then Google Places');
  logger.info('✅ Quality: Activity-specific prompts');
  logger.info('═══════════════════════════════════════════════════════════════\n');

  // Step 1: Delete old trips for Barcelona and Paris
  logger.info('🗑️  Step 1: Deleting old trips for Barcelona and Paris...');
  const { error: deleteError } = await supabase
    .from('public_trips')
    .delete()
    .in('city', ['Barcelona', 'Paris']);

  if (deleteError) {
    logger.warn(`⚠️  Delete warning: ${deleteError.message}`);
  } else {
    logger.info('✅ Old trips deleted\n');
  }

  // Step 2: Generate trips for each city and activity
  let successCount = 0;
  let failCount = 0;

  for (const city of TARGET_CITIES) {
    logger.info(`\n${'═'.repeat(60)}`);
    logger.info(`🏙️  CITY: ${city.name}, ${city.country}`);
    logger.info(`   Activities: ${city.activities.join(', ')}`);
    logger.info(`${'═'.repeat(60)}\n`);

    for (const activity of city.activities) {
      const tripResult = await generateHybridTrip(city, activity, 3);

      if (tripResult) {
        successCount++;
      } else {
        failCount++;
      }

      // Small delay between trips
      logger.info(`  ⏳ Waiting 2s before next trip...\n`);
      await sleep(2000);
    }
  }

  // Summary
  const duration = (Date.now() - startTime) / 1000;
  logger.info('\n═══════════════════════════════════════════════════════════════');
  logger.info('📊 GENERATION SUMMARY');
  logger.info('═══════════════════════════════════════════════════════════════');
  logger.info(`✅ Successful: ${successCount}/${TARGET_CITIES.reduce((sum, c) => sum + c.activities.length, 0)}`);
  logger.info(`❌ Failed: ${failCount}`);
  logger.info(`⏱️  Total duration: ${duration.toFixed(2)}s`);
  logger.info('═══════════════════════════════════════════════════════════════\n');

  if (successCount === TARGET_CITIES.reduce((sum, c) => sum + c.activities.length, 0)) {
    logger.info('🎉 ALL TRIPS GENERATED SUCCESSFULLY!');
  } else {
    logger.warn(`⚠️  Some trips failed. Check logs above.`);
  }

  process.exit(0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Utility Functions
// ═══════════════════════════════════════════════════════════════════════════

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// Run
// ═══════════════════════════════════════════════════════════════════════════

main().catch((error) => {
  logger.error('❌ Fatal error:', error);
  process.exit(1);
});
