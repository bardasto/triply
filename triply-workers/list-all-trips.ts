import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';

const supabase = getSupabaseAdmin();

async function listAllTrips() {
  logger.info('📋 Listing ALL trips in database...\n');

  const { data: trips, error } = await supabase
    .from('public_trips')
    .select('id, title, city, country, activity_type, created_at, data_sources')
    .in('city', ['Barcelona', 'Paris'])
    .order('created_at', { ascending: false });

  if (error) {
    logger.error('❌ Error:', error.message);
    return;
  }

  logger.info(`Found ${trips?.length || 0} trips\n`);

  const tripsWithRestaurants = [];
  const tripsWithoutRestaurants = [];

  for (const trip of trips || []) {
    // Fetch full trip with itinerary
    const { data: fullTrip } = await supabase
      .from('public_trips')
      .select('itinerary')
      .eq('id', trip.id)
      .single();

    const hasRestaurants = fullTrip?.itinerary?.some((day: any) =>
      day.restaurants && Array.isArray(day.restaurants) && day.restaurants.length > 0
    );

    const restaurantsCount = fullTrip?.itinerary?.reduce((sum: number, day: any) =>
      sum + (day.restaurants?.length || 0), 0
    ) || 0;

    const tripInfo = {
      ...trip,
      hasRestaurants,
      restaurantsCount,
      structure: trip.data_sources?.structure || 'unknown'
    };

    if (hasRestaurants) {
      tripsWithRestaurants.push(tripInfo);
    } else {
      tripsWithoutRestaurants.push(tripInfo);
    }
  }

  logger.info('✅ TRIPS WITH RESTAURANTS (Hybrid V2):');
  logger.info('═'.repeat(80));
  for (const trip of tripsWithRestaurants) {
    logger.info(`🍽️  ${trip.city} - ${trip.activity_type}`);
    logger.info(`   "${trip.title}"`);
    logger.info(`   ID: ${trip.id}`);
    logger.info(`   Restaurants: ${trip.restaurantsCount}`);
    logger.info(`   Structure: ${trip.structure}`);
    logger.info(`   Created: ${new Date(trip.created_at).toLocaleString()}`);
    logger.info('');
  }

  logger.info('\n❌ TRIPS WITHOUT RESTAURANTS (Old structure):');
  logger.info('═'.repeat(80));
  for (const trip of tripsWithoutRestaurants) {
    logger.info(`📍 ${trip.city} - ${trip.activity_type}`);
    logger.info(`   "${trip.title}"`);
    logger.info(`   ID: ${trip.id}`);
    logger.info(`   Structure: ${trip.structure}`);
    logger.info(`   Created: ${new Date(trip.created_at).toLocaleString()}`);
    logger.info('');
  }

  logger.info('\n📊 SUMMARY:');
  logger.info(`✅ With restaurants: ${tripsWithRestaurants.length}`);
  logger.info(`❌ Without restaurants: ${tripsWithoutRestaurants.length}`);
  logger.info(`📈 Total: ${trips?.length || 0}`);
}

listAllTrips()
  .then(() => process.exit(0))
  .catch((error) => {
    logger.error('❌ Error:', error);
    process.exit(1);
  });
