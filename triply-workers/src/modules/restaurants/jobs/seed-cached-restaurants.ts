/**
 * ═══════════════════════════════════════════════════════════════════════════
 * Seed Cached Restaurants Job
 * Seed restaurant catalog with Google-compliant caching
 * ═══════════════════════════════════════════════════════════════════════════
 */

import logger from '../../../../shared/utils/logger.js';
import RestaurantCacheService from '../services/restaurant-cache.service.js';

// ═══════════════════════════════════════════════════════════════════════════
// City Configurations
// ═══════════════════════════════════════════════════════════════════════════

interface CityConfig {
  name: string;
  countryCode: string;
  cuisines: string[];
  perCuisineLimit: number;
}

const CITIES: Record<string, CityConfig> = {
  paris: {
    name: 'Paris',
    countryCode: 'FR',
    cuisines: ['French', 'Italian', 'Japanese', 'Mediterranean', 'Vietnamese'],
    perCuisineLimit: 20,
  },
  london: {
    name: 'London',
    countryCode: 'GB',
    cuisines: ['British', 'Indian', 'Italian', 'Chinese', 'Middle Eastern'],
    perCuisineLimit: 20,
  },
  tokyo: {
    name: 'Tokyo',
    countryCode: 'JP',
    cuisines: ['Japanese', 'Sushi', 'Ramen', 'Tempura', 'Italian'],
    perCuisineLimit: 20,
  },
  'new-york': {
    name: 'New York',
    countryCode: 'US',
    cuisines: ['American', 'Italian', 'Chinese', 'Mexican', 'Japanese'],
    perCuisineLimit: 20,
  },
};

// ═══════════════════════════════════════════════════════════════════════════
// Seed Functions
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Seed restaurants for Paris
 */
export async function seedParisRestaurants() {
  logger.info('🗼 Seeding Paris restaurants...\n');

  const config = CITIES.paris;
  const result = await RestaurantCacheService.seedMultipleCuisines(
    config.name,
    config.countryCode,
    config.cuisines,
    config.perCuisineLimit
  );

  logSeedResult(config.name, result);
  return result;
}

/**
 * Seed restaurants for London
 */
export async function seedLondonRestaurants() {
  logger.info('🇬🇧 Seeding London restaurants...\n');

  const config = CITIES.london;
  const result = await RestaurantCacheService.seedMultipleCuisines(
    config.name,
    config.countryCode,
    config.cuisines,
    config.perCuisineLimit
  );

  logSeedResult(config.name, result);
  return result;
}

/**
 * Seed restaurants for Tokyo
 */
export async function seedTokyoRestaurants() {
  logger.info('🗾 Seeding Tokyo restaurants...\n');

  const config = CITIES.tokyo;
  const result = await RestaurantCacheService.seedMultipleCuisines(
    config.name,
    config.countryCode,
    config.cuisines,
    config.perCuisineLimit
  );

  logSeedResult(config.name, result);
  return result;
}

/**
 * Seed restaurants for all configured cities
 */
export async function seedAllCities() {
  logger.info('🌍 Seeding restaurants for all cities...\n');

  const results: Record<string, any> = {};

  for (const [cityKey, config] of Object.entries(CITIES)) {
    logger.info(`\n${'═'.repeat(80)}`);
    logger.info(`Seeding ${config.name}...`);
    logger.info('═'.repeat(80) + '\n');

    const result = await RestaurantCacheService.seedMultipleCuisines(
      config.name,
      config.countryCode,
      config.cuisines,
      config.perCuisineLimit
    );

    results[cityKey] = result;
    logSeedResult(config.name, result);

    // Wait between cities to avoid rate limiting
    logger.info('\n⏳ Waiting 5 seconds before next city...\n');
    await sleep(5000);
  }

  // Overall summary
  logger.info('\n' + '═'.repeat(80));
  logger.info('📊 Overall Seed Summary');
  logger.info('═'.repeat(80));

  let totalCached = 0;
  let totalFailed = 0;

  for (const [cityKey, result] of Object.entries(results)) {
    totalCached += result.cached;
    totalFailed += result.failed;
    logger.info(
      `${CITIES[cityKey].name}: ${result.cached} cached, ${result.failed} failed`
    );
  }

  logger.info('─'.repeat(80));
  logger.info(`Total: ${totalCached} cached, ${totalFailed} failed`);
  logger.info('═'.repeat(80));

  return results;
}

/**
 * Seed specific cuisines for a city
 */
export async function seedCustom(
  city: string,
  countryCode: string,
  cuisines: string[],
  perCuisineLimit: number = 20
) {
  logger.info(`🍽️ Custom seed: ${city}\n`);

  const result = await RestaurantCacheService.seedMultipleCuisines(
    city,
    countryCode,
    cuisines,
    perCuisineLimit
  );

  logSeedResult(city, result);
  return result;
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper Functions
// ═══════════════════════════════════════════════════════════════════════════

function logSeedResult(city: string, result: any) {
  logger.info('\n' + '═'.repeat(80));
  logger.info(`📊 ${city} Seed Result`);
  logger.info('═'.repeat(80));
  logger.info(`Total Restaurants:  ${result.total}`);
  logger.info(`✅ Cached:          ${result.cached}`);
  logger.info(`❌ Failed:          ${result.failed}`);
  logger.info(
    `Success Rate:       ${result.total > 0 ? Math.round((result.cached / result.total) * 100) : 0}%`
  );
  logger.info('═'.repeat(80));

  if (result.errors.length > 0) {
    logger.error('\n🚨 Errors:');
    result.errors.slice(0, 10).forEach((err: string, i: number) => {
      logger.error(`  ${i + 1}. ${err}`);
    });
    if (result.errors.length > 10) {
      logger.error(`  ... and ${result.errors.length - 10} more errors`);
    }
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ═══════════════════════════════════════════════════════════════════════════
// CLI Execution
// ═══════════════════════════════════════════════════════════════════════════

if (import.meta.url === `file://${process.argv[1]}`) {
  (async () => {
    try {
      const args = process.argv.slice(2);
      const command = args[0];

      switch (command) {
        case 'paris':
          await seedParisRestaurants();
          break;

        case 'london':
          await seedLondonRestaurants();
          break;

        case 'tokyo':
          await seedTokyoRestaurants();
          break;

        case 'all':
          await seedAllCities();
          break;

        case 'custom':
          // Example: npm run seed:restaurants custom "Barcelona" "ES" "Spanish,Seafood" 15
          const city = args[1];
          const countryCode = args[2];
          const cuisines = args[3]?.split(',') || [];
          const limit = parseInt(args[4] || '20');

          if (!city || !countryCode || cuisines.length === 0) {
            logger.error('Usage: npm run seed:restaurants custom <city> <country_code> <cuisines> [limit]');
            logger.error('Example: npm run seed:restaurants custom "Barcelona" "ES" "Spanish,Seafood" 15');
            process.exit(1);
          }

          await seedCustom(city, countryCode, cuisines, limit);
          break;

        default:
          logger.info('Available commands:');
          logger.info('  npm run seed:restaurants paris');
          logger.info('  npm run seed:restaurants london');
          logger.info('  npm run seed:restaurants tokyo');
          logger.info('  npm run seed:restaurants all');
          logger.info('  npm run seed:restaurants custom <city> <country_code> <cuisines> [limit]');
          process.exit(1);
      }

      logger.info('\n✅ Seed completed successfully');
      process.exit(0);
    } catch (error) {
      logger.error('Seed execution failed:', error);
      process.exit(1);
    }
  })();
}
