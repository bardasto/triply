/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Enrich Restaurants with Full Opening Hours from Google Places Details API
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * This script fetches complete opening_hours data (with weekday_text) for restaurants
 * that currently have incomplete or missing opening_hours data.
 */

import getSupabaseAdmin from '../../../../shared/config/supabase.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import logger from '../../../../shared/utils/logger.js';

const BATCH_SIZE = 50; // Process restaurants in batches
const DELAY_MS = 300; // Delay between API calls to respect rate limits

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Main function to enrich restaurants with opening hours
 */
async function enrichRestaurantsOpeningHours(): Promise<void> {
  const supabase = getSupabaseAdmin();

  logger.info('🔍 Fetching restaurants that need opening hours enrichment...');

  // Fetch restaurants that have google_place_id but missing/incomplete opening_hours
  const { data: restaurants, error } = await supabase
    .from('restaurants')
    .select('id, name, google_place_id, opening_hours')
    .eq('is_active', true)
    .not('google_place_id', 'is', null)
    .limit(BATCH_SIZE);

  if (error) {
    logger.error('❌ Failed to fetch restaurants:', error);
    return;
  }

  if (!restaurants || restaurants.length === 0) {
    logger.info('✅ No restaurants found to enrich');
    return;
  }

  logger.info(`📦 Found ${restaurants.length} restaurants to process`);

  let enrichedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const restaurant of restaurants) {
    try {
      // Skip if already has weekday_text
      if (
        restaurant.opening_hours &&
        typeof restaurant.opening_hours === 'object' &&
        restaurant.opening_hours.weekday_text &&
        restaurant.opening_hours.weekday_text.length > 0
      ) {
        logger.debug(`⏭️  Skipping "${restaurant.name}" - already has weekday_text`);
        skippedCount++;
        continue;
      }

      // Fetch full place details
      logger.info(`🔄 Fetching details for "${restaurant.name}" (${restaurant.google_place_id})...`);

      const placeDetails = await googlePlacesService.getPlaceDetails(restaurant.google_place_id);

      if (!placeDetails) {
        logger.warn(`⚠️  No details found for "${restaurant.name}"`);
        errorCount++;
        await sleep(DELAY_MS);
        continue;
      }

      // Update with full opening_hours
      const { error: updateError } = await supabase
        .from('restaurants')
        .update({
          opening_hours: placeDetails.opening_hours || null,
        })
        .eq('id', restaurant.id);

      if (updateError) {
        logger.error(`❌ Failed to update "${restaurant.name}":`, updateError);
        errorCount++;
      } else {
        const hasWeekdayText = placeDetails.opening_hours?.weekday_text?.length > 0;
        logger.info(
          `✅ Enriched "${restaurant.name}" - ` +
          `${hasWeekdayText ? `${placeDetails.opening_hours.weekday_text.length} days` : 'no weekday_text'}`
        );
        enrichedCount++;
      }

      // Delay to respect API rate limits
      await sleep(DELAY_MS);

    } catch (err) {
      logger.error(`❌ Error processing "${restaurant.name}":`, err);
      errorCount++;
    }
  }

  logger.info('\n═══════════════════════════════════════════════════════════');
  logger.info('📊 ENRICHMENT SUMMARY');
  logger.info(`   ✅ Enriched: ${enrichedCount}`);
  logger.info(`   ⏭️  Skipped (already complete): ${skippedCount}`);
  logger.info(`   ❌ Errors: ${errorCount}`);
  logger.info('═══════════════════════════════════════════════════════════\n');
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  logger.info('🚀 Starting restaurant opening hours enrichment...\n');

  enrichRestaurantsOpeningHours()
    .then(() => {
      logger.info('✅ Enrichment completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('❌ Enrichment failed:', error);
      process.exit(1);
    });
}

export default enrichRestaurantsOpeningHours;
