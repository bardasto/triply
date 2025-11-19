/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Seed Paris Restaurants
 * Collects detailed restaurant data for 15 restaurants in Paris
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { getSupabaseAdmin } from '../../../../shared/config/supabase.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import type { PlaceDetails } from '../../google-places/services/google-places.service.js';
import logger from '../../../../shared/utils/logger.js';
import {
  Restaurant,
  RestaurantInput,
  RestaurantPhoto,
  RestaurantReview,
  OpeningHours,
} from '../../../../shared/types/index.js';

// ═══════════════════════════════════════════════════════════════════════════
// Configuration
// ═══════════════════════════════════════════════════════════════════════════

const PARIS_LOCATION = { lat: 48.8566, lng: 2.3522 };
const TARGET_RESTAURANTS = 15;
const SEARCH_RADIUS = 5000; // 5km from city center

// ═══════════════════════════════════════════════════════════════════════════
// Main Function
// ═══════════════════════════════════════════════════════════════════════════

export async function seedParisRestaurants() {
  const startTime = Date.now();
  logger.info('🍽️  Starting Paris restaurants seeding process...');

  const supabase = getSupabaseAdmin();

  try {
    // Step 1: Search for top restaurants in Paris
    logger.info(`📍 Searching for restaurants in Paris using Text Search...`);

    const restaurants = await googlePlacesService.textSearch({
      query: 'fine dining michelin restaurant in Paris',
      location: PARIS_LOCATION,
      radius: SEARCH_RADIUS,
      type: 'restaurant'
    });

    // Filter and sort by rating
    const topRestaurants = restaurants
      .filter(r => r.rating && r.rating >= 4.0)
      .sort((a, b) => (b.rating || 0) - (a.rating || 0))
      .slice(0, TARGET_RESTAURANTS);

    logger.info(`✅ Found ${topRestaurants.length} top-rated restaurants`);

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

        // Step 3: Save restaurant to database
        const restaurantId = await saveRestaurant(supabase, details);

        if (!restaurantId) {
          logger.warn(`⚠️  Could not save ${restaurant.name}`);
          errorCount++;
          continue;
        }

        // Step 4: Save photos
        if (details.photos && details.photos.length > 0) {
          await saveRestaurantPhotos(supabase, restaurantId, details);
          logger.info(`  📸 Saved ${details.photos.length} photos`);
        }

        // Step 5: Save reviews
        if (details.reviews && details.reviews.length > 0) {
          await saveRestaurantReviews(supabase, restaurantId, details);
          logger.info(`  📝 Saved ${details.reviews.length} reviews`);
        }

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

    // Extract features
    const features: string[] = [];
    if (details.opening_hours?.open_now) features.push('open_now');

    // Build restaurant input
    const restaurantInput: RestaurantInput = {
      name: details.name,
      description: extractDescription(details),
      cuisine_types: cuisineTypes,
      address: details.formatted_address,
      latitude: details.geometry.location.lat,
      longitude: details.geometry.location.lng,
      phone: details.formatted_phone_number,
      website: details.website,
      rating: details.rating,
      google_rating: details.rating,
      google_review_count: details.user_ratings_total || 0,
      price_level: details.price_level,
      google_place_id: details.place_id,
      opening_hours: details.opening_hours as OpeningHours,
      features,
      dietary_options: []
    };

    // Insert restaurant
    const { data, error } = await supabase
      .from('restaurants')
      .insert({
        ...restaurantInput,
        review_count: details.user_ratings_total || 0,
        currency: 'EUR',
        has_menu: false,
        is_active: true,
        last_verified_at: new Date().toISOString()
      })
      .select('id')
      .single();

    if (error) {
      logger.error('  ❌ Database error:', error.message);
      return null;
    }

    logger.info(`  ✅ Saved restaurant with ID: ${data.id}`);
    return data.id;
  } catch (error) {
    logger.error('  ❌ Error saving restaurant:', error);
    return null;
  }
}

async function saveRestaurantPhotos(
  supabase: any,
  restaurantId: string,
  details: PlaceDetails
): Promise<void> {
  try {
    if (!details.photos || details.photos.length === 0) {
      logger.info('  ℹ️  No photos available');
      return;
    }

    const photos = details.photos.slice(0, 10).map((photo, index) => ({
      restaurant_id: restaurantId,
      photo_url: `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photo.photo_reference}&key=${process.env.GOOGLE_PLACES_API_KEY}`,
      photo_reference: photo.photo_reference,
      photo_type: index === 0 ? 'exterior' : 'food', // Simple classification
      source: 'google_places',
      display_order: index,
      is_primary: index === 0
    }));

    const { data, error } = await supabase
      .from('restaurant_photos')
      .insert(photos)
      .select();

    if (error) {
      logger.error('  ❌ Error saving photos:', {
        code: error.code,
        message: error.message,
        details: error.details,
        hint: error.hint
      });
    } else {
      logger.info(`  ✅ Saved ${data?.length || photos.length} photos successfully`);
    }
  } catch (error: any) {
    logger.error('  ❌ Error in saveRestaurantPhotos:', {
      message: error.message,
      stack: error.stack
    });
  }
}

async function saveRestaurantReviews(
  supabase: any,
  restaurantId: string,
  details: PlaceDetails
): Promise<void> {
  try {
    if (!details.reviews || details.reviews.length === 0) return;

    const reviews = details.reviews.map((review: any) => ({
      restaurant_id: restaurantId,
      author_name: review.author_name,
      author_profile_url: review.author_url,
      rating: review.rating,
      comment: review.text,
      source: 'google',
      external_review_id: review.time?.toString(),
      sentiment_score: calculateSentimentScore(review.rating),
      sentiment_label: getSentimentLabel(review.rating),
      helpful_count: 0,
      review_date: review.time ? new Date(review.time * 1000).toISOString() : new Date().toISOString()
    }));

    const { error } = await supabase
      .from('restaurant_reviews')
      .insert(reviews);

    if (error) {
      logger.error('  ❌ Error saving reviews:', error.message);
    }
  } catch (error) {
    logger.error('  ❌ Error in saveRestaurantReviews:', error);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Utility Functions
// ═══════════════════════════════════════════════════════════════════════════

function extractCuisineTypes(types: string[]): string[] {
  const cuisineMap: Record<string, string> = {
    'french_restaurant': 'French',
    'italian_restaurant': 'Italian',
    'japanese_restaurant': 'Japanese',
    'chinese_restaurant': 'Chinese',
    'indian_restaurant': 'Indian',
    'mexican_restaurant': 'Mexican',
    'thai_restaurant': 'Thai',
    'vietnamese_restaurant': 'Vietnamese',
    'korean_restaurant': 'Korean',
    'mediterranean_restaurant': 'Mediterranean',
    'american_restaurant': 'American',
    'seafood_restaurant': 'Seafood',
    'steakhouse': 'Steakhouse',
    'vegetarian_restaurant': 'Vegetarian',
    'vegan_restaurant': 'Vegan',
    'bistro': 'French Bistro',
    'brasserie': 'French Brasserie'
  };

  const cuisines: string[] = [];

  for (const type of types) {
    const cuisine = cuisineMap[type];
    if (cuisine && !cuisines.includes(cuisine)) {
      cuisines.push(cuisine);
    }
  }

  // Default to French if no specific cuisine found (we're in Paris!)
  if (cuisines.length === 0 && types.includes('restaurant')) {
    cuisines.push('French');
  }

  return cuisines;
}

function extractDescription(details: PlaceDetails): string | undefined {
  // Try to construct a description from available data
  const parts: string[] = [];

  if (details.rating) {
    parts.push(`Rated ${details.rating}/5`);
  }

  if (details.user_ratings_total) {
    parts.push(`based on ${details.user_ratings_total} reviews`);
  }

  if (details.price_level) {
    const priceSymbol = '€'.repeat(details.price_level);
    parts.push(`Price range: ${priceSymbol}`);
  }

  return parts.length > 0 ? parts.join(' • ') : undefined;
}

function calculateSentimentScore(rating: number): number {
  // Convert 1-5 rating to -1 to 1 sentiment score
  return (rating - 3) / 2;
}

function getSentimentLabel(rating: number): 'positive' | 'neutral' | 'negative' {
  if (rating >= 4) return 'positive';
  if (rating >= 3) return 'neutral';
  return 'negative';
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// Run if called directly
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  seedParisRestaurants()
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
}

export default seedParisRestaurants;
