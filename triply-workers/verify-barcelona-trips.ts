import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';

const supabase = getSupabaseAdmin();

logger.info('📊 Verifying ALL Barcelona trips for diversity...\n');

const { data: trips, error } = await supabase
  .from('public_trips')
  .select('*')
  .eq('city', 'Barcelona')
  .order('activity_type');

if (error) {
  logger.error('Error fetching trips:', error);
  process.exit(1);
}

if (!trips || trips.length === 0) {
  logger.warn('No trips found for Barcelona');
  process.exit(0);
}

logger.info(`Found ${trips.length} trips for Barcelona\n`);
logger.info('='.repeat(80));

trips.forEach((trip, index) => {
  logger.info(`\n${index + 1}. ${trip.activity_type.toUpperCase()} - "${trip.title}"`);
  logger.info('-'.repeat(80));

  // Extract all places from all days
  const allPlaces: any[] = [];
  trip.itinerary?.forEach((day: any) => {
    day.places?.forEach((place: any) => {
      allPlaces.push(place);
    });
  });

  logger.info(`Total places: ${allPlaces.length}`);

  // Group by type
  const typeGroups: Record<string, number> = {};
  allPlaces.forEach((place) => {
    const type = place.type || 'unknown';
    typeGroups[type] = (typeGroups[type] || 0) + 1;
  });

  logger.info('\nPlace types:');
  Object.entries(typeGroups)
    .sort((a, b) => b[1] - a[1])
    .forEach(([type, count]) => {
      logger.info(`  - ${type}: ${count}`);
    });

  // Show first 5 places
  logger.info('\nSample places:');
  allPlaces.slice(0, 5).forEach((place, idx) => {
    logger.info(`  ${idx + 1}. ${place.name} (${place.type})`);
  });
});

logger.info('\n' + '='.repeat(80));
logger.info('🎯 DIVERSITY CHECK');
logger.info('='.repeat(80));

// Check for diversity across all trips
const allActivityTypes = new Set(trips.map((t) => t.activity_type));
logger.info(`\n✅ Activity types covered: ${allActivityTypes.size}/11`);
allActivityTypes.forEach((type) => logger.info(`  - ${type}`));

// Extract all unique place names across all trips
const allPlaceNames = new Set<string>();
trips.forEach((trip) => {
  trip.itinerary?.forEach((day: any) => {
    day.places?.forEach((place: any) => {
      allPlaceNames.add(place.name);
    });
  });
});

logger.info(`\n✅ Unique places across all trips: ${allPlaceNames.size}`);

// Check for activity-specific places
logger.info('\n📍 Activity-specific place verification:');

const activityKeywords: Record<string, string[]> = {
  cycling: ['bike', 'cycling', 'marítim', 'verda', 'trail', 'path'],
  beach: ['beach', 'playa', 'barceloneta', 'bogatell', 'bar', 'coastal'],
  skiing: ['ski', 'resort', 'molina', 'slope', 'mountain'],
  mountains: ['tibidabo', 'mountain', 'montserrat', 'peak', 'viewpoint'],
  hiking: ['trail', 'hiking', 'carretera', 'aigües', 'hike'],
  sailing: ['marina', 'port', 'sailing', 'yacht', 'boat'],
  desert: ['desert', 'bardenas', 'arid', 'canyon'],
  camping: ['camping', 'campsite', 'campground'],
  city: ['sagrada', 'gaudí', 'gothic', 'rambla', 'museum'],
  wellness: ['spa', 'aire', 'yoga', 'wellness', 'thermal'],
  road_trip: ['road', 'drive', 'route', 'scenic'],
};

trips.forEach((trip) => {
  const keywords = activityKeywords[trip.activity_type] || [];
  const allPlaces: any[] = [];
  trip.itinerary?.forEach((day: any) => {
    day.places?.forEach((place: any) => {
      allPlaces.push(place);
    });
  });

  const matchingPlaces = allPlaces.filter((place) => {
    const combined = `${place.name} ${place.type}`.toLowerCase();
    return keywords.some((keyword) => combined.includes(keyword));
  });

  const relevance = allPlaces.length > 0 ? (matchingPlaces.length / allPlaces.length) * 100 : 0;
  const status = relevance > 50 ? '✅' : relevance > 25 ? '⚠️ ' : '❌';

  logger.info(`${status} ${trip.activity_type}: ${relevance.toFixed(0)}% activity-specific places (${matchingPlaces.length}/${allPlaces.length})`);
});

logger.info('\n' + '='.repeat(80));
logger.info('✅ Verification complete!');
logger.info('='.repeat(80));

process.exit(0);
