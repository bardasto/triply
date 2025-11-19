import { createClient } from '@supabase/supabase-js';
import config from './src/shared/config/env.js';

const supabase = createClient(
  config.SUPABASE_URL,
  config.SUPABASE_SERVICE_ROLE_KEY
);

async function checkRestaurantImages() {
  console.log(`🔍 Checking restaurants in database...`);
  console.log(`   Supabase URL: ${config.SUPABASE_URL}`);

  const { data, error } = await supabase
    .from('restaurants')
    .select('id, name, image_url, images')
    .ilike('address', '%Paris%')
    .limit(5);

  if (error) {
    console.error('❌ Error:', error);
  } else {
    console.log(`\n✅ Found ${data.length} restaurants from database:\n`);
    data.forEach((r: any) => {
      console.log(`  📍 ${r.name}`);
      console.log(`     ID: ${r.id}`);
      console.log(`     image_url: ${r.image_url ? '✓ EXISTS' : '✗ NULL'}`);
      console.log(`     images: ${r.images ? `✓ Array(${r.images.length})` : '✗ NULL'}`);
      if (r.images && r.images.length > 0) {
        console.log(`       → First: ${r.images[0].substring(0, 80)}...`);
      }
      console.log('');
    });
  }
}

checkRestaurantImages().catch(console.error);
