/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Fetch Restaurant Photos
 * Updates photos for existing restaurants in database
 * ═══════════════════════════════════════════════════════════════════════════
 */

import { getSupabaseAdmin } from '../../../../shared/config/supabase.js';
import googlePlacesService from '../../google-places/services/google-places.service.js';
import logger from '../../../../shared/utils/logger.js';

async function fetchRestaurantPhotos(options?: {
  force?: boolean; // Force re-fetch even if photos exist
  maxPhotos?: number; // Max photos per restaurant (default 15)
}) {
  const startTime = Date.now();
  const force = options?.force || false;
  const maxPhotos = options?.maxPhotos || 15;

  logger.info('📸 Starting restaurant photos update...');
  logger.info(`   Force mode: ${force ? 'YES (will replace existing)' : 'NO (skip existing)'}`);
  logger.info(`   Max photos per restaurant: ${maxPhotos}`);

  const supabase = getSupabaseAdmin();

  try {
    // Get all restaurants that have google_place_id
    const { data: restaurants, error: fetchError } = await supabase
      .from('restaurants')
      .select('id, name, google_place_id')
      .not('google_place_id', 'is', null);

    if (fetchError) {
      logger.error('❌ Error fetching restaurants:', fetchError);
      return;
    }

    if (!restaurants || restaurants.length === 0) {
      logger.warn('⚠️  No restaurants found with google_place_id');
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
          if (!force) {
            logger.info(`  ℹ️  Already has ${existingPhotos} photos, skipping... (use force=true to replace)`);
            successCount++;
            continue;
          } else {
            // Delete existing photos in force mode
            logger.info(`  🗑️  Deleting ${existingPhotos} existing photos...`);
            const { error: deleteError } = await supabase
              .from('restaurant_photos')
              .delete()
              .eq('restaurant_id', restaurant.id);

            if (deleteError) {
              logger.error('  ❌ Error deleting old photos:', deleteError.message);
              errorCount++;
              continue;
            }
            logger.info(`  ✅ Deleted old photos`);
          }
        }

        // Get place details from Google
        logger.info(`  🔍 Fetching details for place_id: ${restaurant.google_place_id}`);

        const details = await googlePlacesService.getPlaceDetails(
          restaurant.google_place_id
        );

        if (!details) {
          logger.warn(`  ⚠️  Could not fetch details from Google`);
          errorCount++;
          continue;
        }

        logger.info(`  ✅ Got details for ${details.name}`);

        // Save photos
        if (!details.photos || details.photos.length === 0) {
          logger.info(`  ℹ️  No photos available from Google`);
          successCount++;
          continue;
        }

        const availablePhotos = Math.min(details.photos.length, maxPhotos);
        logger.info(`  📸 Found ${details.photos.length} photos from Google, taking ${availablePhotos}`);

        // Build photo objects with higher quality (maxwidth=1200)
        const photos = details.photos.slice(0, availablePhotos).map((photo, index) => ({
          restaurant_id: restaurant.id,
          photo_url: `https://maps.googleapis.com/maps/api/place/photo?maxwidth=1200&photoreference=${photo.photo_reference}&key=${process.env.GOOGLE_PLACES_API_KEY}`,
          photo_reference: photo.photo_reference,
          photo_type: index === 0 ? 'exterior' : 'food', // Simple classification
          source: 'google_places',
          display_order: index,
          is_primary: index === 0,
        }));

        // Insert photos
        const { data: insertedPhotos, error: photoError } = await supabase
          .from('restaurant_photos')
          .insert(photos)
          .select();

        if (photoError) {
          logger.error('  ❌ Error inserting photos:', {
            code: photoError.code,
            message: photoError.message,
            details: photoError.details,
            hint: photoError.hint,
          });
          errorCount++;
        } else {
          const savedCount = insertedPhotos?.length || 0;
          logger.info(`  ✅ Saved ${savedCount} photos`);
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
    logger.info('📊 PHOTOS UPDATE SUMMARY');
    logger.info('═══════════════════════════════════════════════════════════════');
    logger.info(`✅ Successfully processed: ${successCount}`);
    logger.info(`❌ Errors: ${errorCount}`);
    logger.info(`📸 Total photos saved: ${totalPhotos}`);
    logger.info(`⏱️  Total duration: ${duration.toFixed(2)}s`);
    logger.info('═══════════════════════════════════════════════════════════════\n');

    return { success: true, count: successCount, totalPhotos, errors: errorCount };
  } catch (error) {
    logger.error('❌ Fatal error in photos update:', error);
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
  // Check for command line arguments
  const args = process.argv.slice(2);
  const force = args.includes('--force') || args.includes('-f');
  const maxPhotosArg = args.find(arg => arg.startsWith('--max='));
  const maxPhotos = maxPhotosArg ? parseInt(maxPhotosArg.split('=')[1]) : 15;

  logger.info('🚀 Starting with options:');
  logger.info(`   Force: ${force}`);
  logger.info(`   Max photos: ${maxPhotos}`);
  logger.info('');

  fetchRestaurantPhotos({ force, maxPhotos })
    .then((result) => {
      if (result) {
        logger.info(
          `✅ Photos update completed: ${result.totalPhotos} photos saved`
        );
      }
      process.exit(0);
    })
    .catch((error) => {
      logger.error('❌ Photos update failed:', error);
      process.exit(1);
    });
}

export default fetchRestaurantPhotos;
