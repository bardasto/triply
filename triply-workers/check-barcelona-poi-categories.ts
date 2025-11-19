import getSupabaseAdmin from './src/shared/config/supabase.js';

const supabase = getSupabaseAdmin();

const { data: barcelona } = await supabase
  .from('cities')
  .select('id')
  .ilike('name', '%Barcelona%')
  .eq('country', 'Spain')
  .single();

if (!barcelona) {
  console.log('Barcelona not found');
  process.exit(1);
}

const { data: pois, error } = await supabase
  .from('pois')
  .select('id, name, category')
  .eq('city_id', barcelona.id);

if (error) {
  console.error('Error:', error);
  process.exit(1);
}

console.log(`\n📊 Barcelona POI Categories (${pois?.length} total):\n`);

const categoryCounts: Record<string, number> = {};
pois?.forEach(poi => {
  categoryCounts[poi.category] = (categoryCounts[poi.category] || 0) + 1;
});

Object.entries(categoryCounts)
  .sort((a, b) => b[1] - a[1])
  .forEach(([category, count]) => {
    console.log(`  ${category}: ${count} POIs`);
  });

process.exit(0);
