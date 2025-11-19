/**
 * Test After Migration 004
 * Verify that restaurants view works correctly
 */

import { createClient } from '@supabase/supabase-js';
import config from './src/config/env.js';

console.log('🔍 Testing restaurants view after Migration 004...\n');

const supabase = createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY);

// Test 1: Simple query (no joins)
console.log('═'.repeat(80));
console.log('Test 1: Simple SELECT * FROM restaurants');
console.log('═'.repeat(80));

const { data: simple, error: simpleError } = await supabase
  .from('restaurants')
  .select('*')
  .limit(3);

if (simpleError) {
  console.error('\n❌ FAILED:', simpleError.message);
  console.log('\n⚠️  Migration 004 was NOT applied!');
  console.log('   Please read: CHECK_AND_FIX.md\n');
  process.exit(1);
} else {
  console.log(`\n✅ SUCCESS: ${simple?.length || 0} restaurants returned\n`);

  if (simple && simple.length > 0) {
    simple.forEach((r, i) => {
      console.log(`${i + 1}. ${r.name}`);
      console.log(`   Rating: ${r.rating}⭐`);
      console.log(`   Photos field: ${r.photos ? 'EXISTS' : 'MISSING'}`);
      console.log(`   Images field: ${r.images ? `${r.images.length} URLs` : 'MISSING'}`);
      console.log(`   Image_url field: ${r.image_url ? 'EXISTS' : 'MISSING'}`);
      console.log('');
    });
  }
}

// Test 2: Flutter's exact query (with photo join)
console.log('\n' + '═'.repeat(80));
console.log('Test 2: Flutter Query with Photo Join');
console.log('═'.repeat(80));

const { data: flutterQuery, error: flutterError } = await supabase
  .from('restaurants')
  .select(`
    *,
    photos:restaurant_photos(*)
  `)
  .eq('is_active', true)
  .ilike('address', '%Paris%')
  .order('rating', { ascending: false });

if (flutterError) {
  console.error('\n❌ Flutter query FAILED:', flutterError.message);
  console.log('\n   This means the view still has the old structure.');
  console.log('   Please apply Migration 004 in Supabase SQL Editor.\n');
} else {
  console.log(`\n✅ Flutter query SUCCESS: ${flutterQuery?.length || 0} restaurants\n`);

  if (flutterQuery && flutterQuery.length > 0) {
    flutterQuery.forEach((r, i) => {
      console.log(`${i + 1}. ${r.name} - ${r.rating}⭐`);
    });
  }
}

// Test 3: Without photo join (simplified)
console.log('\n' + '═'.repeat(80));
console.log('Test 3: Simplified Query (No Photo Join)');
console.log('═'.repeat(80));

const { data: simplified, error: simplifiedError } = await supabase
  .from('restaurants')
  .select('*')
  .eq('is_active', true)
  .ilike('address', '%Paris%')
  .order('rating', { ascending: false });

if (simplifiedError) {
  console.error('\n❌ FAILED:', simplifiedError.message);
} else {
  console.log(`\n✅ Simplified query SUCCESS: ${simplified?.length || 0} restaurants\n`);

  if (simplified && simplified.length > 0) {
    simplified.forEach((r, i) => {
      console.log(`${i + 1}. ${r.name}`);
      console.log(`   Photos: ${r.images?.length || 0}`);
      console.log(`   Primary photo: ${r.image_url ? 'YES' : 'NO'}`);
      console.log('');
    });
  }
}

// Summary
console.log('\n' + '═'.repeat(80));
console.log('📊 Test Summary');
console.log('═'.repeat(80));

const allPassed =
  !simpleError &&
  simple &&
  simple.length > 0 &&
  simple[0].photos &&
  simple[0].images &&
  simple[0].image_url;

if (allPassed) {
  console.log('✅ All tests PASSED!');
  console.log('✅ Migration 004 was successfully applied');
  console.log('✅ Restaurants view includes photos');
  console.log('✅ Flutter app should now work!');
  console.log('\nNext steps:');
  console.log('1. Restart Flutter app (hot restart with "R")');
  console.log('2. Open any trip');
  console.log('3. Click "View All" in restaurants section');
  console.log('4. You should see 5 restaurants on the map ✅');
} else {
  console.log('❌ Tests FAILED');
  console.log('❌ Migration 004 was NOT applied correctly');
  console.log('\n⚠️  Please apply Migration 004 manually:');
  console.log('   1. Read: CHECK_AND_FIX.md');
  console.log('   2. Open Supabase SQL Editor');
  console.log('   3. Copy SQL from: scripts/migrations/004_fix_restaurants_view_with_photos.sql');
  console.log('   4. Execute');
}

console.log('═'.repeat(80));
console.log('');
