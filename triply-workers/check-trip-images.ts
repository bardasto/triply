import getSupabaseAdmin from './src/shared/config/supabase.js';

const supabase = getSupabaseAdmin();

const { data: trips, error } = await supabase
  .from('public_trips')
  .select('id, title, hero_image_url, itinerary')
  .eq('city', 'Barcelona')
  .limit(1);

if (error) {
  console.error('Error:', error);
} else if (trips && trips.length > 0) {
  const trip = trips[0];
  console.log('Trip:', trip.title);
  console.log('Hero image:', trip.hero_image_url?.substring(0, 100) + '...');
  console.log('');
  console.log('First day places:');
  const firstDay = trip.itinerary[0];
  const firstPlace = firstDay.places[0];
  console.log('Place:', firstPlace.name);
  console.log('Images type:', typeof firstPlace.images);
  console.log('Images is array:', Array.isArray(firstPlace.images));
  console.log('Images count:', firstPlace.images?.length || 0);
  if (firstPlace.images && firstPlace.images.length > 0) {
    console.log('\nFirst image structure:');
    console.log(JSON.stringify(firstPlace.images[0], null, 2));
    console.log('\nFirst image URL (first 150 chars):');
    console.log(firstPlace.images[0].url.substring(0, 150) + '...');
  }
}

process.exit(0);
