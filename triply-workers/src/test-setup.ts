
import config from './config/env.js';
import logger from './utils/logger.js';
import getSupabaseAdmin from './config/supabase.js';

async function testSetup() {
  logger.info('🧪 Testing setup...');

  // Test config
  logger.info(`Environment: ${config.NODE_ENV}`);
  logger.info(`Supabase URL: ${config.SUPABASE_URL}`);

  // Test Supabase connection
  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from('cities')
    .select('count')
    .limit(1);

  if (error) {
    logger.error('❌ Supabase connection failed', error);
  } else {
    logger.info('✅ Supabase connection successful');
  }

  logger.info('🎉 Setup test complete!');
}

testSetup().catch(err => {
  logger.error('Test failed:', err);
  process.exit(1);
});

