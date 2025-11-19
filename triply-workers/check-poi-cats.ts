import getSupabaseAdmin from './src/shared/config/supabase.js';

const supabase = getSupabaseAdmin();
const barcelonaId = 'd0045c38-048f-4f44-976f-c91b94d2b900';

const { data: pois } = await supabase
  .from('pois')
  .select('category')
  .eq('city_id', barcelonaId);

console.log(`\n📊 Barcelona POI Categories (${pois?.length} total):\n`);

const counts: Record<string, number> = {};
pois?.forEach(p => {
  counts[p.category] = (counts[p.category] || 0) + 1;
});

Object.entries(counts)
  .sort((a, b) => b[1] - a[1])
  .forEach(([cat, count]) => {
    console.log(`  ${cat}: ${count}`);
  });
