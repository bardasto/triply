/**
 * Check POI categories in database for Barcelona and Paris
 * To understand what categories we have and adjust filtering
 */

import getSupabaseAdmin from './src/shared/config/supabase.js';

async function checkPOICategories() {
  const supabase = getSupabaseAdmin();

  console.log('═══════════════════════════════════════════════════════');
  console.log('📋 Checking POI Categories in Database');
  console.log('═══════════════════════════════════════════════════════\n');

  const cities = ['Barcelona', 'Paris'];

  for (const cityName of cities) {
    console.log(`\n🏙️  ${cityName}`);
    console.log('─────────────────────────────────────────────────────\n');

    // Get city ID
    const { data: city } = await supabase
      .from('cities')
      .select('id, name')
      .eq('name', cityName)
      .single();

    if (!city) {
      console.log(`❌ City not found: ${cityName}\n`);
      continue;
    }

    // Get all POIs for this city
    const { data: pois } = await supabase
      .from('pois')
      .select('id, name, category')
      .eq('city_id', city.id);

    if (!pois || pois.length === 0) {
      console.log(`❌ No POIs found for ${cityName}\n`);
      continue;
    }

    // Count POIs by category
    const categoryCounts: Record<string, number> = {};
    const categoryExamples: Record<string, string[]> = {};

    pois.forEach(poi => {
      const category = poi.category || 'unknown';
      categoryCounts[category] = (categoryCounts[category] || 0) + 1;

      if (!categoryExamples[category]) {
        categoryExamples[category] = [];
      }
      if (categoryExamples[category].length < 3) {
        categoryExamples[category].push(poi.name);
      }
    });

    // Sort by count
    const sortedCategories = Object.entries(categoryCounts)
      .sort(([, a], [, b]) => b - a);

    console.log(`Total POIs: ${pois.length}\n`);
    console.log('Categories (sorted by count):\n');

    sortedCategories.forEach(([category, count]) => {
      const percentage = ((count / pois.length) * 100).toFixed(1);
      const examples = categoryExamples[category].join(', ');
      console.log(`  ${category.padEnd(25)} ${count.toString().padStart(3)} (${percentage.padStart(5)}%)  Examples: ${examples}`);
    });

    console.log('');
  }

  console.log('═══════════════════════════════════════════════════════');
  console.log('✅ Category check complete!');
  console.log('═══════════════════════════════════════════════════════\n');

  console.log('💡 Use these actual categories in getRelevantPOICategories()');
  console.log('   to ensure proper filtering for each activity type.\n');
}

checkPOICategories()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
