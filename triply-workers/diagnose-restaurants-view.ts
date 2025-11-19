/**
 * Diagnose Restaurants View
 * Tests if the SQL view returns data correctly
 */

import { createClient } from '@supabase/supabase-js';
import config from './src/config/env.js';

console.log('🔍 Diagnosing restaurants view...\n');

const supabase = createClient(config.SUPABASE_URL, config.SUPABASE_SERVICE_ROLE_KEY);

// Test 1: Check if view exists and returns data
console.log('═'.repeat(80));
console.log('Test 1: Query restaurants view directly');
console.log('═'.repeat(80));

const { data: allFromView, error: viewError } = await supabase
  .from('restaurants')
  .select('*')
  .limit(10);

if (viewError) {
  console.error('❌ Error querying restaurants view:', viewError);
} else {
  console.log(`✅ Found ${allFromView?.length || 0} restaurants in view\n`);

  if (allFromView && allFromView.length > 0) {
    allFromView.forEach((r, i) => {
      console.log(`${i + 1}. ${r.name}`);
      console.log(`   Address: ${r.address}`);
      console.log(`   Rating: ${r.rating || 'N/A'}`);
      console.log(`   Active: ${r.is_active}`);
      console.log('');
    });
  } else {
    console.log('⚠️ View exists but returns no data');
  }
}

// Test 2: Test exact query Flutter uses
console.log('\n' + '═'.repeat(80));
console.log('Test 2: Simulate Flutter query (with city filter)');
console.log('═'.repeat(80));

const testCity = 'Paris';
console.log(`\nQuerying: SELECT * FROM restaurants WHERE is_active = true AND address ILIKE '%${testCity}%'\n`);

const { data: flutterQuery, error: flutterError } = await supabase
  .from('restaurants')
  .select(`
    *,
    photos:restaurant_photos(*)
  `)
  .eq('is_active', true)
  .ilike('address', `%${testCity}%`)
  .order('rating', { ascending: false });

if (flutterError) {
  console.error('❌ Flutter query failed:', flutterError);
} else {
  console.log(`✅ Flutter query returned ${flutterQuery?.length || 0} restaurants\n`);

  if (flutterQuery && flutterQuery.length > 0) {
    flutterQuery.forEach((r, i) => {
      console.log(`${i + 1}. ${r.name}`);
      console.log(`   Address: ${r.address}`);
      console.log(`   Rating: ${r.rating || 'N/A'}`);
      console.log(`   Photos: ${r.photos?.length || 0}`);
      console.log('');
    });
  } else {
    console.log(`⚠️ No restaurants found for city: ${testCity}`);
    console.log('   Possible reasons:');
    console.log('   1. No restaurants in cache for this city');
    console.log('   2. City name mismatch (check spelling/case)');
    console.log('   3. Address field format issue');
  }
}

// Test 3: Check underlying cache data
console.log('\n' + '═'.repeat(80));
console.log('Test 3: Check places_cache data directly');
console.log('═'.repeat(80));

const { data: cacheData, error: cacheError } = await supabase
  .from('places_cache')
  .select(`
    name,
    formatted_address,
    rating,
    expires_at,
    place_catalog:place_catalog_id (
      city,
      place_type,
      is_active
    )
  `)
  .limit(10);

if (cacheError) {
  console.error('❌ Error querying cache:', cacheError);
} else {
  console.log(`\nFound ${cacheData?.length || 0} entries in places_cache:\n`);

  if (cacheData && cacheData.length > 0) {
    cacheData.forEach((entry, i) => {
      const catalog = entry.place_catalog as any;
      console.log(`${i + 1}. ${entry.name}`);
      console.log(`   City: ${catalog?.city || 'N/A'}`);
      console.log(`   Type: ${catalog?.place_type || 'N/A'}`);
      console.log(`   Active: ${catalog?.is_active}`);
      console.log(`   Address: ${entry.formatted_address}`);
      console.log(`   Expires: ${entry.expires_at}`);
      console.log('');
    });
  } else {
    console.log('⚠️ No data in places_cache - need to seed restaurants');
  }
}

// Test 4: Test without city filter
console.log('\n' + '═'.repeat(80));
console.log('Test 4: Get all restaurants (no city filter)');
console.log('═'.repeat(80));

const { data: allRestaurants, error: allError } = await supabase
  .from('restaurants')
  .select('*')
  .eq('is_active', true);

if (allError) {
  console.error('❌ Error:', allError);
} else {
  console.log(`\n✅ Total active restaurants: ${allRestaurants?.length || 0}\n`);

  if (allRestaurants && allRestaurants.length > 0) {
    const cities = new Set(
      allRestaurants
        .map(r => r.address)
        .filter(a => a)
        .map(a => {
          // Extract city from address
          const parts = a.split(',');
          return parts[parts.length - 2]?.trim() || 'Unknown';
        })
    );

    console.log('Cities found in addresses:');
    cities.forEach(city => console.log(`  - ${city}`));
  }
}

// Summary
console.log('\n' + '═'.repeat(80));
console.log('📊 Diagnostic Summary');
console.log('═'.repeat(80));
console.log(`View accessible: ${viewError ? '❌' : '✅'}`);
console.log(`View has data: ${allFromView && allFromView.length > 0 ? '✅' : '❌'}`);
console.log(`Flutter query works: ${flutterError ? '❌' : '✅'}`);
console.log(`Flutter query returns data: ${flutterQuery && flutterQuery.length > 0 ? '✅' : '❌'}`);
console.log(`Cache has data: ${cacheData && cacheData.length > 0 ? '✅' : '❌'}`);
console.log('═'.repeat(80));

if (!allFromView || allFromView.length === 0) {
  console.log('\n⚠️ ROOT CAUSE: View returns no data');
  console.log('   Next steps:');
  console.log('   1. Check if places_cache has expired entries');
  console.log('   2. Run: npm run test:verify-cached-data');
  console.log('   3. Re-seed if needed: npm run seed:restaurants:paris');
}

if (flutterQuery && flutterQuery.length === 0 && allRestaurants && allRestaurants.length > 0) {
  console.log('\n⚠️ ROOT CAUSE: City name mismatch');
  console.log(`   Query is looking for "${testCity}" in address`);
  console.log('   But addresses may contain different format');
  console.log('   Next steps:');
  console.log('   1. Check address format in database');
  console.log('   2. Update city filter logic');
}

console.log('');
