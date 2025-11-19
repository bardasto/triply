import { importPOIsForCities } from './src/modules/pois/jobs/import-pois-for-cities.js';
import logger from './src/shared/utils/logger.js';

// Barcelona and Paris city IDs
const cityIds = [
  'd0045c38-048f-4f44-976f-c91b94d2b900', // Barcelona, Spain
  '56501812-c4a4-4840-80c6-3ce6ef0a9d6e', // Paris, France
];

logger.info('🚀 Starting POI import for Barcelona and Paris with 100+ types');
logger.info(`   Cities: ${cityIds.length}`);
logger.info(`   POIs per city: 100`);

importPOIsForCities({
  cityIds,
  poisPerCity: 100, // Увеличиваем до 100 POI на город
  dryRun: false,
})
  .then((result) => {
    logger.info('✅ POI import finished', result);
    process.exit(0);
  })
  .catch((error) => {
    logger.error('❌ POI import failed', error);
    process.exit(1);
  });
