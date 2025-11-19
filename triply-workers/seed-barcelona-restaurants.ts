/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Seed Barcelona Restaurants
 * Collects detailed restaurant data for 25 restaurants in Barcelona
 * ═══════════════════════════════════════════════════════════════════════════
 */

import getSupabaseAdmin from './src/shared/config/supabase.js';
import googlePlacesService from './src/modules/google-places/services/google-places.service.js';
import type { PlaceDetails } from './src/modules/google-places/services/google-places.service.js';
import logger from './src/shared/utils/logger.js';

// ═══════════════════════════════════════════════════════════════════════════
// Configuration
// ═══════════════════════════════════════════════════════════════════════════

const BARCELONA_LOCATION = { lat: 41.3851, lng: 2.1734 };
const TARGET_RESTAURANTS = 25;
const SEARCH_RADIUS = 5000; // 5km from city center

// Different search queries to get variety
const SEARCH_QUERIES = [
  'fine dining restaurant in Barcelona',
  'tapas bar in Barcelona',
  'seafood restaurant in Barcelona',
  'traditional catalan restaurant in Barcelona',
  'michelin restaurant in Barcelona',
];

// ═══════════════════════════════════════════════════════════════════════════
// Main Function
// ═══════════════════════════════════════════════════════════════════════════

async function seedBarcelonaRestaurants() {
  const startTime = Date.now();
  logger.info('🍽️  Starting Barcelona restaurants seeding process...');

  const supabase = getSupabaseAdmin();

  try {
    const allRestaurants: any[] = [];

    // Search with multiple queries for variety
    for (const query of SEARCH_QUERIES) {
      logger.info(`📍 Searching: "${query}"...`);

      const restaurants = await googlePlacesService.textSearch({
        query,
        location: BARCELONA_LOCATION,
        radius: SEARCH_RADIUS,
        type: 'restaurant'
      });

      allRestaurants.push(...restaurants);
      logger.info(`  Found ${restaurants.length} restaurants`);

      // Rate limiting
      await sleep(500);
    }

    // Remove duplicates by place_id and sort by rating
    const uniqueRestaurants = Array.from(
      new Map(allRestaurants.map(r => [r.place_id, r])).values()
    );

    const topRestaurants = uniqueRestaurants
      .filter(r => r.rating && r.rating >= 4.0)
      .sort((a, b) => (b.rating || 0) - (a.rating || 0))
      .slice(0, TARGET_RESTAURANTS);

    logger.info(`\n✅ Selected ${topRestaurants.length} top-rated restaurants`);

    // Step 2: Process each restaurant
    let successCount = 0;
    let errorCount = 0;

    for (let i = 0; i < topRestaurants.length; i++) {
      const restaurant = topRestaurants[i];
      logger.info(`\n📍 [${i + 1}/${topRestaurants.length}] Processing: ${restaurant.name}`);

      try {
        // Get detailed information
        const details = await googlePlacesService.getPlaceDetails(restaurant.place_id);

        if (!details) {
          logger.warn(`⚠️  Could not get details for ${restaurant.name}`);
          errorCount++;
          continue;
        }

        // Step 3: Save restaurant to database (includes photos and reviews in cache)
        const restaurantId = await saveRestaurant(supabase, details);

        if (!restaurantId) {
          logger.warn(`⚠️  Could not save ${restaurant.name}`);
          errorCount++;
          continue;
        }

        logger.info(`  📸 Cached ${details.photos?.length || 0} photos`);
        logger.info(`  📝 Cached ${details.reviews?.length || 0} reviews`);

        successCount++;
        logger.info(`  ✅ Successfully processed ${restaurant.name}`);

        // Rate limiting
        await sleep(1000);
      } catch (error) {
        logger.error(`  ❌ Error processing ${restaurant.name}:`, error);
        errorCount++;
      }
    }

    // Summary
    const duration = (Date.now() - startTime) / 1000;
    logger.info('\n═══════════════════════════════════════════════════════════════');
    logger.info('📊 SEEDING SUMMARY');
    logger.info('═══════════════════════════════════════════════════════════════');
    logger.info(`✅ Successfully processed: ${successCount}`);
    logger.info(`❌ Errors: ${errorCount}`);
    logger.info(`⏱️  Total duration: ${duration.toFixed(2)}s`);
    logger.info('═══════════════════════════════════════════════════════════════\n');

    return { success: true, count: successCount, errors: errorCount };
  } catch (error) {
    logger.error('❌ Fatal error in seeding process:', error);
    throw error;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════════

async function saveRestaurant(
  supabase: any,
  details: PlaceDetails
): Promise<string | null> {
  try {
    // Extract cuisine types from Google Places types
    const cuisineTypes = extractCuisineTypes(details.types);

    // Step 1: Create catalog entry
    const { data: catalogData, error: catalogError } = await supabase
      .from('places_catalog')
      .upsert({
        google_place_id: details.place_id,
        latitude: details.geometry.location.lat,
        longitude: details.geometry.location.lng,
        coordinates_cached_at: new Date().toISOString(),
        city: 'Barcelona',
        country_code: 'ES',
        place_type: 'restaurant',
        category: 'dining',
        tags: ['restaurant'],
        priority: 0,
        is_active: true,
      }, { onConflict: 'google_place_id' })
      .select('id')
      .single();

    if (catalogError) {
      logger.error('  ❌ Catalog error:', catalogError.message);
      return null;
    }

    const catalogId = catalogData.id;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30 days
    const nextRefreshAt = new Date(now.getTime() + 15 * 24 * 60 * 60 * 1000); // 15 days

    // Step 2: Cache place data
    const { data: cacheData, error: cacheError } = await supabase
      .from('places_cache')
      .upsert({
        place_catalog_id: catalogId,
        name: details.name,
        formatted_address: details.formatted_address,
        international_phone_number: details.formatted_phone_number,
        website: details.website,
        rating: details.rating,
        user_ratings_total: details.user_ratings_total || 0,
        price_level: details.price_level,
        cuisine_types: cuisineTypes,
        opening_hours: details.opening_hours,
        is_open_now: details.opening_hours?.open_now,
        photos: details.photos?.map((p) => ({
          photo_reference: p.photo_reference,
          width: 800,
          height: 600,
        })),
        reviews: details.reviews?.slice(0, 5).map((r: any) => ({
          author_name: r.author_name,
          rating: r.rating,
          text: r.text,
          time: r.time,
        })),
        business_status: 'OPERATIONAL',
        types: details.types,
        editorial_summary: null,
        raw_data: details,
        cached_at: now.toISOString(),
        expires_at: expiresAt.toISOString(),
        next_refresh_at: nextRefreshAt.toISOString(),
        last_api_call_at: now.toISOString(),
      }, { onConflict: 'place_catalog_id' })
      .select('id')
      .single();

    if (cacheError) {
      logger.error('  ❌ Cache error:', cacheError.message);
      return null;
    }

    logger.info(`  ✅ Saved restaurant with ID: ${catalogId}`);
    return catalogId;
  } catch (error) {
    logger.error('  ❌ Error saving restaurant:', error);
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Utility Functions
// ═══════════════════════════════════════════════════════════════════════════

function extractCuisineTypes(types: string[]): string[] {
  const cuisineMap: Record<string, string> = {
    'spanish_restaurant': 'Spanish',
    'catalan_restaurant': 'Catalan',
    'tapas_restaurant': 'Tapas',
    'seafood_restaurant': 'Seafood',
    'mediterranean_restaurant': 'Mediterranean',
    'italian_restaurant': 'Italian',
    'french_restaurant': 'French',
    'japanese_restaurant': 'Japanese',
    'chinese_restaurant': 'Chinese',
    'indian_restaurant': 'Indian',
    'mexican_restaurant': 'Mexican',
    'thai_restaurant': 'Thai',
    'vietnamese_restaurant': 'Vietnamese',
    'korean_restaurant': 'Korean',
    'american_restaurant': 'American',
    'steakhouse': 'Steakhouse',
    'vegetarian_restaurant': 'Vegetarian',
    'vegan_restaurant': 'Vegan',
  };

  const cuisines: string[] = [];

  for (const type of types) {
    const cuisine = cuisineMap[type];
    if (cuisine && !cuisines.includes(cuisine)) {
      cuisines.push(cuisine);
    }
  }

  // Default to Spanish/Mediterranean if no specific cuisine found
  if (cuisines.length === 0 && types.includes('restaurant')) {
    cuisines.push('Spanish', 'Mediterranean');
  }

  return cuisines;
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// Run
// ═══════════════════════════════════════════════════════════════════════════

seedBarcelonaRestaurants()
  .then((result) => {
    logger.info(`✅ Seeding completed: ${result.count} restaurants processed`);
    process.exit(0);
  })
  .catch((error) => {
    logger.error('❌ Seeding failed:', {
      message: error.message,
      stack: error.stack,
      name: error.name
    });
    console.error('\n❌ Full error details:', error);
    process.exit(1);
  });
