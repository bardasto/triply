/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Enrich POIs with Full Opening Hours from Google Places Details API
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * This script fetches complete opening_hours data (with weekday_text) for POIs
 * that currently have incomplete data from nearbySearch API.
 */

import getSupabaseAdmin from '../../../../shared/config/supabase.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import logger from '../../../../shared/utils/logger.js';

const BATCH_SIZE = 50; // Process POIs in batches
const DELAY_MS = 300; // Delay between API calls to respect rate limits

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Main function to enrich POIs with opening hours
 */
async function enrichPOIsOpeningHours(): Promise<void> {
  const supabase = getSupabaseAdmin();

  logger.info('🔍 Fetching POIs that need opening hours enrichment...');

  // Fetch POIs that have external_id (Google Place ID) but missing weekday_text
  const { data: pois, error } = await supabase
    .from('pois')
    .select('id, name, external_id, metadata')
    .not('external_id', 'is', null)
    .limit(BATCH_SIZE);

  if (error) {
    logger.error('❌ Failed to fetch POIs:', error);
    return;
  }

  if (!pois || pois.length === 0) {
    logger.info('✅ No POIs found to enrich');
    return;
  }

  logger.info(`📦 Found ${pois.length} POIs to process`);

  let enrichedCount = 0;
  let skippedCount = 0;
  let errorCount = 0;

  for (const poi of pois) {
    try {
      // Skip if already has weekday_text
      if (
        poi.metadata?.opening_hours &&
        typeof poi.metadata.opening_hours === 'object' &&
        poi.metadata.opening_hours.weekday_text
      ) {
        logger.debug(`⏭️  Skipping "${poi.name}" - already has weekday_text`);
        skippedCount++;
        continue;
      }

      // Fetch full place details
      logger.info(`🔄 Fetching details for "${poi.name}" (${poi.external_id})...`);

      const placeDetails = await googlePlacesService.getPlaceDetails(poi.external_id);

      if (!placeDetails) {
        logger.warn(`⚠️  No details found for "${poi.name}"`);
        errorCount++;
        await sleep(DELAY_MS);
        continue;
      }

      // Update metadata with full opening_hours
      const updatedMetadata = {
        ...poi.metadata,
        opening_hours: placeDetails.opening_hours || null,
      };

      const { error: updateError } = await supabase
        .from('pois')
        .update({ metadata: updatedMetadata })
        .eq('id', poi.id);

      if (updateError) {
        logger.error(`❌ Failed to update "${poi.name}":`, updateError);
        errorCount++;
      } else {
        const hasWeekdayText = placeDetails.opening_hours?.weekday_text?.length > 0;
        logger.info(
          `✅ Enriched "${poi.name}" - ` +
          `${hasWeekdayText ? `${placeDetails.opening_hours.weekday_text.length} days` : 'no weekday_text'}`
        );
        enrichedCount++;
      }

      // Delay to respect API rate limits
      await sleep(DELAY_MS);

    } catch (err) {
      logger.error(`❌ Error processing "${poi.name}":`, err);
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
  logger.info('🚀 Starting POI opening hours enrichment...\n');

  enrichPOIsOpeningHours()
    .then(() => {
      logger.info('✅ Enrichment completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      logger.error('❌ Enrichment failed:', error);
      process.exit(1);
    });
}

export default enrichPOIsOpeningHours;
