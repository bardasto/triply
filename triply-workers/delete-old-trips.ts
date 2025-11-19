import getSupabaseAdmin from './src/shared/config/supabase.js';

const supabase = getSupabaseAdmin();

console.log('🗑️  Deleting old trips for Barcelona and Paris...');

const { data, error } = await supabase
  .from('public_trips')
  .delete()
  .or('city.ilike.%Barcelona%,city.ilike.%Paris%');

if (error) {
  console.error('❌ Error:', error);
  process.exit(1);
} else {
  console.log('✅ Old trips deleted successfully');
}

process.exit(0);
