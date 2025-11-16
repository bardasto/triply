/**
 * Test: Generate trips for 2 cities (Barcelona, Paris)
 */

import generateEuropeanTrips from './src/jobs/generate-trips.js';
import logger from './src/utils/logger.js';

console.log('╔══════════════════════════════════════════════════════════════╗');
console.log('║   Тестовая генерация трипов для 2 городов                   ║');
console.log('║   Проверяем несколько фотографий для каждого места           ║');
console.log('╚══════════════════════════════════════════════════════════════╝\n');

console.log('🎯 Цель: Проверить, что у каждого места есть несколько фотографий');
console.log('📍 Города: Paris, Barcelona');
console.log('🎨 Активности: По 1 трипу на город');
console.log('⏱️  Примерное время: 2-3 минуты\n');

console.log('Press Ctrl+C to cancel...\n');

generateEuropeanTrips({
  testMode: false, // Use ONLY Paris and Barcelona
  maxCities: 2,
  activitiesPerCity: 1,
  dryRun: false,
  delayBetweenTrips: 2000,
  targetCities: ['Paris', 'Barcelona'], // Only these 2 cities
})
  .then(result => {
    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('✅ ГЕНЕРАЦИЯ ЗАВЕРШЕНА');
    console.log(`   Трипов создано: ${result.stats.totalTrips}`);
    console.log(`   Успешно: ${result.stats.successful}`);
    console.log(`   Ошибок: ${result.stats.failed}`);
    console.log('═══════════════════════════════════════════════════════════════\n');
    process.exit(0);
  })
  .catch(error => {
    logger.error('💥 Ошибка генерации:', error);
    process.exit(1);
  });
