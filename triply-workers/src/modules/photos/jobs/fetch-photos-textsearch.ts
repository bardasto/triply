/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Fetch Restaurant Photos using Text Search
 * Uses Text Search API instead of Place Details (which requires separate billing)
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { getSupabaseAdmin } from '../../../../shared/config/supabase.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import logger from '../../../../shared/utils/logger.js';

async function fetchPhotosTextSearch() {
  const startTime = Date.now();
  logger.info('📸 Starting restaurant photos fetch using Text Search...');

  const supabase = getSupabaseAdmin();

  try {
    // Get all restaurants
    const { data: restaurants, error: fetchError } = await supabase
      .from('restaurants')
      .select('id, name, address, google_place_id')
      .not('google_place_id', 'is', null);

    if (fetchError) {
      logger.error('❌ Error fetching restaurants:', fetchError);
      return;
    }

    if (!restaurants || restaurants.length === 0) {
      logger.warn('⚠️  No restaurants found');
      return;
    }

    logger.info(`✅ Found ${restaurants.length} restaurants to process`);

    let successCount = 0;
    let errorCount = 0;
    let totalPhotos = 0;

    for (let i = 0; i < restaurants.length; i++) {
      const restaurant = restaurants[i];

      logger.info(`\n📍 [${i + 1}/${restaurants.length}] ${restaurant.name}`);

      try {
        // Check if photos already exist
        const { count: existingPhotos } = await supabase
          .from('restaurant_photos')
          .select('*', { count: 'exact', head: true })
          .eq('restaurant_id', restaurant.id);

        if (existingPhotos && existingPhotos > 0) {
          logger.info(`  ℹ️  Already has ${existingPhotos} photos, skipping...`);
          successCount++;
          continue;
        }

        // Use Text Search to get restaurant data with photos
        logger.info(`  🔍 Searching via Text Search...`);

        const results = await googlePlacesService.textSearch({
          query: `${restaurant.name} ${restaurant.address || 'Paris'}`,
        });

        if (!results || results.length === 0) {
          logger.warn(`  ⚠️  Not found in Text Search`);
          errorCount++;
          continue;
        }

        const place = results[0]; // Take first result
        logger.info(`  ✅ Found: ${place.name}`);

        // Check if place has photos
        if (!place.photos || place.photos.length === 0) {
          logger.info(`  ℹ️  No photos available`);
          successCount++;
          continue;
        }

        logger.info(`  📸 Found ${place.photos.length} photo(s)`);

        // Build photo objects
        const photos = place.photos.map((photo, index) => ({
          restaurant_id: restaurant.id,
          photo_url: `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${photo.photo_reference}&key=${process.env.GOOGLE_PLACES_API_KEY}`,
          photo_reference: photo.photo_reference,
          photo_type: index === 0 ? 'exterior' : 'food',
          source: 'google_places',
          display_order: index,
          is_primary: index === 0,
          width: photo.width,
          height: photo.height,
        }));

        // Insert photos
        const { data: insertedPhotos, error: photoError } = await supabase
          .from('restaurant_photos')
          .insert(photos)
          .select();

        if (photoError) {
          logger.error('  ❌ Error inserting photos:');
          logger.error(`     Code: ${photoError.code}`);
          logger.error(`     Message: ${photoError.message}`);
          logger.error(`     Details: ${photoError.details}`);
          logger.error(`     Hint: ${photoError.hint}`);
          logger.error('     Photo data:', JSON.stringify(photos, null, 2));
          errorCount++;
        } else {
          const savedCount = insertedPhotos?.length || 0;
          logger.info(`  ✅ Saved ${savedCount} photo(s)`);
          totalPhotos += savedCount;
          successCount++;
        }

        // Rate limiting
        await sleep(500);
      } catch (error: any) {
        logger.error(`  ❌ Error processing ${restaurant.name}:`, error.message);
        errorCount++;
      }
    }

    // Summary
    const duration = (Date.now() - startTime) / 1000;
    logger.info('\n═══════════════════════════════════════════════════════════════');
    logger.info('📊 PHOTOS FETCH SUMMARY');
    logger.info('═══════════════════════════════════════════════════════════════');
    logger.info(`✅ Successfully processed: ${successCount}`);
    logger.info(`❌ Errors: ${errorCount}`);
    logger.info(`📸 Total photos saved: ${totalPhotos}`);
    logger.info(`⏱️  Total duration: ${duration.toFixed(2)}s`);
    logger.info('═══════════════════════════════════════════════════════════════\n');

    return { success: true, count: successCount, totalPhotos, errors: errorCount };
  } catch (error) {
    logger.error('❌ Fatal error in photos fetch:', error);
    throw error;
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// Run if called directly
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  fetchPhotosTextSearch()
    .then((result) => {
      if (result) {
        logger.info(
          `✅ Photos fetch completed: ${result.totalPhotos} photos saved`
        );
      }
      process.exit(0);
    })
    .catch((error) => {
      logger.error('❌ Photos fetch failed:', error);
      process.exit(1);
    });
}

export default fetchPhotosTextSearch;
