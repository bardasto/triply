import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';

const supabase = getSupabaseAdmin();

async function checkBeachTrip() {
  // Barcelona Beach Escapade
  const tripId = 'fa072f03-f6aa-40e9-8a70-e92b32d2615f';

  logger.info('🔍 Checking Barcelona Beach trip in database...\n');

  const { data: trip, error } = await supabase
    .from('public_trips')
    .select('*')
    .eq('id', tripId)
    .single();

  if (error) {
    logger.error('❌ Error:', error.message);
    return;
  }

  logger.info(`📍 Trip: ${trip.title}`);
  logger.info(`🆔 ID: ${trip.id}\n`);

  if (!trip.itinerary) {
    logger.error('❌ No itinerary!');
    return;
  }

  logger.info('📋 CHECKING EACH DAY:\n');

  for (const day of trip.itinerary) {
    logger.info(`Day ${day.day}: ${day.title}`);

    // Check what fields exist
    logger.info(`  Fields in day object: ${Object.keys(day).join(', ')}`);

    // Check places
    logger.info(`  📍 places: ${day.places ? `Array[${day.places.length}]` : 'MISSING'}`);

    // Check restaurants
    logger.info(`  🍽️  restaurants: ${day.restaurants ? `Array[${day.restaurants.length}]` : 'MISSING'}`);

    if (day.restaurants && day.restaurants.length > 0) {
      logger.info(`\n  🍽️  RESTAURANTS:`);
      for (const r of day.restaurants) {
        logger.info(`     - ${r.name} (${r.category})`);
        logger.info(`       Cuisine: ${r.cuisine}`);
        logger.info(`       Images: ${r.images?.length || 0}`);
      }
    } else {
      logger.warn(`  ⚠️  NO RESTAURANTS IN DAY ${day.day}`);
    }

    logger.info('');
  }

  // Show raw JSON for day 1
  logger.info('\n📄 RAW JSON for Day 1 restaurants field:');
  logger.info(JSON.stringify(trip.itinerary[0].restaurants, null, 2).substring(0, 2000));
}

checkBeachTrip()
  .then(() => process.exit(0))
  .catch((error) => {
    logger.error('❌ Error:', error);
    process.exit(1);
  });
