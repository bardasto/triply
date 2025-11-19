import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';

const supabase = getSupabaseAdmin();

logger.info('📊 Checking POI statistics...\n');

// Total POIs
const { count: totalPois } = await supabase
  .from('pois')
  .select('*', { count: 'exact', head: true });

logger.info(`✅ Total POIs: ${totalPois || 0}`);

// POIs by city
const { data: cities } = await supabase
  .from('cities')
  .select('id, name, country')
  .eq('is_active', true)
  .order('name');

logger.info('\n📍 POIs by city:');
logger.info('─'.repeat(60));

for (const city of cities || []) {
  const { count } = await supabase
    .from('pois')
    .select('*', { count: 'exact', head: true })
    .eq('city_id', city.id);

  const status = (count || 0) >= 10 ? '✅' : '⚠️ ';
  logger.info(`${status} ${city.name}, ${city.country}: ${count || 0} POIs`);
}

// POIs by category
logger.info('\n📋 POIs by category:');
logger.info('─'.repeat(60));

const { data: categoryStats } = await supabase
  .from('pois')
  .select('category')
  .eq('is_active', true);

const categoryCount = (categoryStats || []).reduce((acc: any, poi: any) => {
  acc[poi.category] = (acc[poi.category] || 0) + 1;
  return acc;
}, {});

Object.entries(categoryCount)
  .sort(([, a]: any, [, b]: any) => b - a)
  .forEach(([category, count]) => {
    logger.info(`  ${category}: ${count}`);
  });

// Restaurants count
logger.info('\n🍽️  Restaurant statistics:');
logger.info('─'.repeat(60));

const { count: restaurantsCount } = await supabase
  .from('restaurants')
  .select('*', { count: 'exact', head: true })
  .eq('is_active', true);

logger.info(`✅ Total restaurants in cache: ${restaurantsCount || 0}`);

// Restaurants by city
const { data: restaurants } = await supabase
  .from('restaurants')
  .select('address')
  .eq('is_active', true);

const restaurantsByCity = (restaurants || []).reduce((acc: any, r: any) => {
  if (r.address) {
    if (r.address.includes('Barcelona')) {
      acc['Barcelona'] = (acc['Barcelona'] || 0) + 1;
    } else if (r.address.includes('Paris')) {
      acc['Paris'] = (acc['Paris'] || 0) + 1;
    }
  }
  return acc;
}, {});

Object.entries(restaurantsByCity).forEach(([city, count]) => {
  logger.info(`  ${city}: ${count} restaurants`);
});

logger.info('\n' + '═'.repeat(60));

process.exit(0);
