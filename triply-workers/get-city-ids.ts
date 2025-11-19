import getSupabaseAdmin from './src/shared/config/supabase.js';

const supabase = getSupabaseAdmin();

const { data, error } = await supabase
  .from('cities')
  .select('id, name, country')
  .or('name.ilike.%Barcelona%,name.ilike.%Paris%');

if (error) {
  console.error('Error:', error);
} else {
  console.log('Cities found:');
  data?.forEach(city => {
    console.log(`  - ${city.name}, ${city.country}: ${city.id}`);
  });
}

process.exit(0);
