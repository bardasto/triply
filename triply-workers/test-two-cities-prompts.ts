/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Test Two Cities with 5 Activities Each - DRY RUN
 * Проверяет правильность промптов для разных активностей без генерации
 * ═══════════════════════════════════════════════════════════════════════════
 */

import getSupabaseAdmin from './src/shared/config/supabase.js';
import { getActivityPrompt, getSupportedActivities } from './src/modules/ai/prompts/index.js';

// Простой логгер
const logger = {
  info: (...args: any[]) => console.log('[INFO]', ...args),
  error: (...args: any[]) => console.error('[ERROR]', ...args),
  warn: (...args: any[]) => console.warn('[WARN]', ...args),
};

// ═══════════════════════════════════════════════════════════════════════════
// Конфигурация теста
// ═══════════════════════════════════════════════════════════════════════════

const TEST_CITIES = ['Barcelona', 'Paris'];
const ACTIVITIES_PER_CITY = 5;

// Выбор активностей в зависимости от города
function selectActivitiesForCity(cityName: string): string[] {
  const name = cityName.toLowerCase();

  // Barcelona - прибрежный город
  if (name.includes('barcelona')) {
    return ['city', 'beach', 'food', 'cultural', 'cycling'];
  }

  // Paris - столица культуры
  if (name.includes('paris')) {
    return ['city', 'cultural', 'food', 'shopping', 'nightlife'];
  }

  // По умолчанию
  return ['city', 'cultural', 'food', 'hiking', 'wellness'];
}

// ═══════════════════════════════════════════════════════════════════════════
// Главная функция проверки
// ═══════════════════════════════════════════════════════════════════════════

async function testTwoCitiesPrompts() {
  const startTime = Date.now();
  const supabase = getSupabaseAdmin();

  logger.info('═══════════════════════════════════════════════════════');
  logger.info('🧪 TEST: Two Cities with 5 Activities Each');
  logger.info('═══════════════════════════════════════════════════════');
  logger.info(`Mode: DRY RUN (no actual generation)`);
  logger.info(`Cities: ${TEST_CITIES.join(', ')}`);
  logger.info(`Activities per city: ${ACTIVITIES_PER_CITY}`);
  logger.info('═══════════════════════════════════════════════════════\n');

  // 1. Получить города из базы данных
  logger.info('📍 Fetching cities from database...');

  const { data: dbCities, error } = await supabase
    .from('cities')
    .select('*')
    .eq('is_active', true)
    .in('name', TEST_CITIES);

  if (error) {
    logger.error('❌ Failed to fetch cities:', error);
    return;
  }

  if (!dbCities || dbCities.length === 0) {
    logger.error('❌ No cities found in database!');
    return;
  }

  logger.info(`✅ Found ${dbCities.length} cities in database\n`);

  // 2. Проверить POIs для каждого города
  const citiesWithPOIs: any[] = [];

  for (const city of dbCities) {
    const { count: poiCount } = await supabase
      .from('pois')
      .select('*', { count: 'exact', head: true })
      .eq('city_id', city.id);

    const { count: restaurantCount } = await supabase
      .from('restaurants')
      .select('*', { count: 'exact', head: true })
      .eq('is_active', true)
      .ilike('address', `%${city.name}%`);

    logger.info(`  ${city.name}:`);
    logger.info(`    - POIs: ${poiCount || 0}`);
    logger.info(`    - Restaurants: ${restaurantCount || 0}`);

    if (poiCount && poiCount >= 10) {
      citiesWithPOIs.push({
        ...city,
        poi_count: poiCount,
        restaurant_count: restaurantCount || 0,
      });
      logger.info(`    ✅ Ready for generation\n`);
    } else {
      logger.warn(`    ⚠️  Insufficient POIs (need at least 10)\n`);
    }
  }

  if (citiesWithPOIs.length === 0) {
    logger.error('❌ No cities with sufficient POIs found');
    return;
  }

  logger.info('═══════════════════════════════════════════════════════\n');

  // 3. Проверить промпты для каждого города и активности
  let totalPrompts = 0;

  for (const city of citiesWithPOIs) {
    const activities = selectActivitiesForCity(city.name);

    logger.info('═══════════════════════════════════════════════════════');
    logger.info(`🏙️  City: ${city.name}, ${city.country}`);
    logger.info(`📊 POIs: ${city.poi_count}, Restaurants: ${city.restaurant_count}`);
    logger.info(`🎯 Activities: ${activities.join(', ')}`);
    logger.info('═══════════════════════════════════════════════════════\n');

    for (const activity of activities) {
      logger.info(`  🎭 Activity: ${activity.toUpperCase()}`);

      // Получить примеры POIs
      const { data: samplePOIs } = await supabase
        .from('pois')
        .select('id, name, category, latitude, longitude')
        .eq('city_id', city.id)
        .limit(5);

      // Получить примеры ресторанов
      const { data: sampleRestaurants } = await supabase
        .from('restaurants')
        .select('id, name, cuisine_types, rating, price_level, address, latitude, longitude')
        .eq('is_active', true)
        .ilike('address', `%${city.name}%`)
        .limit(3);

      const poiListJson = JSON.stringify(
        (samplePOIs || []).map(poi => ({
          id: poi.id,
          name: poi.name,
          category: poi.category,
          lat: poi.latitude,
          lon: poi.longitude,
        })),
        null,
        2
      );

      const restaurantListJson = JSON.stringify(
        (sampleRestaurants || []).map(r => ({
          id: r.id,
          name: r.name,
          cuisine_types: r.cuisine_types,
          rating: r.rating,
          price_level: r.price_level,
          address: r.address,
          lat: r.latitude,
          lon: r.longitude,
        })),
        null,
        2
      );

      // Сгенерировать промпт
      try {
        const prompt = getActivityPrompt({
          city: city.name,
          country: city.country,
          activity,
          durationDays: 3,
          poiListJson,
          restaurantListJson,
          language: 'en',
        });

        // Проверить содержимое промпта
        const promptLower = prompt.toLowerCase();
        const hasActivityKeywords = checkActivityKeywords(activity, promptLower);

        if (hasActivityKeywords) {
          logger.info(`    ✅ Prompt generated successfully`);
          logger.info(`    📝 Length: ${prompt.length} characters`);
          logger.info(`    🎯 Contains activity-specific keywords: YES`);
        } else {
          logger.warn(`    ⚠️  Prompt generated but missing specific keywords`);
          logger.info(`    📝 Length: ${prompt.length} characters`);
        }

        totalPrompts++;
      } catch (error) {
        logger.error(`    ❌ Failed to generate prompt:`, error);
      }

      logger.info('');
    }

    logger.info('');
  }

  const duration = Date.now() - startTime;

  logger.info('═══════════════════════════════════════════════════════');
  logger.info('🎉 TEST COMPLETE!');
  logger.info('═══════════════════════════════════════════════════════');
  logger.info(`✅ Cities checked: ${citiesWithPOIs.length}`);
  logger.info(`✅ Prompts generated: ${totalPrompts}`);
  logger.info(`⏱️  Duration: ${(duration / 1000).toFixed(1)} seconds`);
  logger.info('═══════════════════════════════════════════════════════\n');

  logger.info('💡 All prompts are ready! To run actual generation:');
  logger.info('   Update generate-trips.ts with these cities and activities');
  logger.info('   Set dryRun: false and execute the generation job');
  logger.info('');

  return {
    citiesChecked: citiesWithPOIs.length,
    promptsGenerated: totalPrompts,
    duration,
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// Вспомогательные функции
// ═══════════════════════════════════════════════════════════════════════════

function checkActivityKeywords(activity: string, promptLower: string): boolean {
  const keywords: Record<string, string[]> = {
    cycling: ['bike', 'cycling', 'cycle', 'bicycle'],
    beach: ['beach', 'coastal', 'swimming', 'sand'],
    mountains: ['mountain', 'summit', 'cable car', 'elevation'],
    hiking: ['hiking', 'trail', 'trek', 'hike'],
    city: ['museum', 'landmark', 'urban', 'monument'],
    cultural: ['museum', 'cultural', 'heritage', 'art'],
    food: ['culinary', 'restaurant', 'gastronomic', 'cuisine'],
    shopping: ['shopping', 'boutique', 'market', 'store'],
    nightlife: ['nightlife', 'club', 'bar', 'evening'],
    wellness: ['wellness', 'spa', 'yoga', 'meditation'],
    skiing: ['ski', 'slope', 'lift', 'snow'],
    sailing: ['sailing', 'boat', 'marina', 'yacht'],
    desert: ['desert', 'dune', 'sand', 'oasis'],
    camping: ['camping', 'tent', 'campfire', 'outdoor'],
    road_trip: ['road trip', 'driving', 'scenic route', 'journey'],
  };

  const activityKeywords = keywords[activity.toLowerCase()] || [];
  return activityKeywords.some(keyword => promptLower.includes(keyword));
}

// ═══════════════════════════════════════════════════════════════════════════
// Запуск теста
// ═══════════════════════════════════════════════════════════════════════════

testTwoCitiesPrompts()
  .then(result => {
    logger.info('✅ Test completed successfully');
    process.exit(0);
  })
  .catch(error => {
    logger.error('💥 Test failed');
    logger.error('Error:', error);
    process.exit(1);
  });
