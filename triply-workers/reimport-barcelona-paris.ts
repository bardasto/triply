import { importPOIsForCities } from './src/modules/pois/jobs/import-pois-for-cities.js';
import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';

const cityIds = [
  'd0045c38-048f-4f44-976f-c91b94d2b900', // Barcelona
  '56501812-c4a4-4840-80c6-3ce6ef0a9d6e', // Paris  
];

// ✅ Delete existing POIs first
logger.info('🗑️  Deleting existing POIs for Barcelona and Paris...');
const supabase = getSupabaseAdmin();
for (const cityId of cityIds) {
  const { error } = await supabase
    .from('pois')
    .delete()
    .eq('city_id', cityId);
  if (error) logger.error('Delete error:', error);
}
logger.info('✅ Existing POIs deleted');

// ✅ Import 300 POIs per city for more variety  
logger.info('🚀 Importing 300 POIs per city with expanded categories');

await importPOIsForCities({
  cityIds,
  poisPerCity: 300,
  dryRun: false,
});

logger.info('✅ Re-import complete!');
process.exit(0);
