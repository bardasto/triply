import getSupabaseAdmin from './src/shared/config/supabase.js';
import logger from './src/shared/utils/logger.js';

const supabase = getSupabaseAdmin();

// Query through the restaurants view
const { data, error } = await supabase
  .from('restaurants')
  .select('*')
  .ilike('address', '%Barcelona%')
  .limit(5);

if (error) {
  logger.error('Query error:', error);
} else {
  logger.info(`Found ${data?.length || 0} restaurants in Barcelona`);
  data?.forEach((r: any) => {
    logger.info(`- ${r.name} (Rating: ${r.rating}, Price: ${'€'.repeat(r.price_level || 0)})`);
  });
}

process.exit(0);
