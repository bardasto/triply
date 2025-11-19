import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';

const supabase = getSupabaseAdmin();

async function verify() {
  // Get one successful trip ID from logs
  const tripId = '99eefaaa-795f-4924-803e-e81a1528ba95'; // Barcelona City trip

  logger.info('🔍 Checking trip in database...\n');

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
  logger.info(`🏙️  City: ${trip.city}`);
  logger.info(`🎯 Activity: ${trip.activity_type}\n`);

  if (!trip.itinerary || trip.itinerary.length === 0) {
    logger.error('❌ No itinerary found!');
    return;
  }

  logger.info('📋 ITINERARY STRUCTURE:\n');

  for (const day of trip.itinerary) {
    logger.info(`Day ${day.day}: ${day.title}`);
    logger.info(`  📍 places field: ${day.places ? `✅ Array with ${day.places.length} items` : '❌ MISSING'}`);
    logger.info(`  🍽️  restaurants field: ${day.restaurants ? `✅ Array with ${day.restaurants.length} items` : '❌ MISSING'}`);

    // Check if restaurants is actually there but empty
    if (day.restaurants !== undefined) {
      logger.info(`  🍽️  Restaurants type: ${typeof day.restaurants}`);
      logger.info(`  🍽️  Restaurants is array: ${Array.isArray(day.restaurants)}`);

      if (day.restaurants && day.restaurants.length > 0) {
        logger.info(`\n  🍽️  RESTAURANTS IN DATABASE:`);
        day.restaurants.forEach((r: any, i: number) => {
          logger.info(`     ${i + 1}. ${r.name || 'NO NAME'} (${r.category || 'no category'})`);
          logger.info(`        Cuisine: ${r.cuisine || 'N/A'}`);
          logger.info(`        Images: ${r.images ? r.images.length : 0}`);
        });
      } else {
        logger.warn(`  ⚠️  restaurants array is EMPTY`);
      }
    } else {
      logger.error(`  ❌ restaurants field does NOT EXIST in database`);
    }

    logger.info('');
  }

  // Also show the raw JSON
  logger.info('\n📄 RAW ITINERARY JSON (first day):');
  logger.info(JSON.stringify(trip.itinerary[0], null, 2).substring(0, 1500));
}

verify()
  .then(() => process.exit(0))
  .catch((error) => {
    logger.error('❌ Error:', error);
    process.exit(1);
  });
